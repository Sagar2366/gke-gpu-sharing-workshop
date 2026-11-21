#!/usr/bin/env bash
# 04-switch-strategy.sh: flip every attendee table GPU between time-sharing and MPS.
#
# On GKE these are two separate node pools. On Plan B each table has ONE GPU VM, so
# the facilitator switches it between labs (the stage GPU t00 stays time-sharing):
#
#   ./scripts/jarvislabs/04-switch-strategy.sh mps   # before Lab 4 (at the break)
#   ./scripts/jarvislabs/04-switch-strategy.sh ts    # before Lab 6 (during Lab 5)
#
# Attendees must have deleted their pods first (Lab 3 and Lab 4 end with clean-up).
# Any pod still on a table GPU is deleted by this script.
set -euo pipefail
cd "$(dirname "$0")"
source ./jl.conf
export KUBECONFIG="$PWD/out/admin.kubeconfig"

case "${1:-}" in
  ts)  cfg=ts4;  strategy=time-sharing ;;
  mps) cfg=mps4; strategy=mps ;;
  *)   echo "usage: $0 ts|mps"; exit 1 ;;
esac

nodes=$(kubectl get nodes -l workshop.devfest/role=table -o jsonpath='{.items[*].metadata.name}')
echo ">> Switching $(echo $nodes | wc -w) table GPUs to $strategy"

for n in $nodes; do
  # remove leftover attendee GPU pods on this node (not system pods)
  kubectl get pods -A --field-selector spec.nodeName="$n" -l '!app.kubernetes.io/managed-by' \
    -o jsonpath='{range .items[*]}{.metadata.namespace}{" "}{.metadata.name}{"\n"}{end}' \
    | grep -E '^t[0-9]+-' | while read -r ns pod; do kubectl -n "$ns" delete pod "$pod" --wait=false; done || true
  kubectl label node "$n" --overwrite >/dev/null \
    nvidia.com/device-plugin.config="$cfg" \
    cloud.google.com/gke-gpu-sharing-strategy="$strategy"
done

echo ">> Waiting for the device plugin to restart with the new config"
for i in $(seq 1 30); do
  ready=0; total=0
  for n in $nodes; do
    total=$((total+1))
    [[ "$(kubectl get node "$n" -o jsonpath='{.status.allocatable.nvidia\.com/gpu}')" == "4" ]] && ready=$((ready+1))
  done
  echo "   $ready/$total nodes advertise 4 shared GPUs"
  [[ $ready == "$total" ]] && break
  sleep 10
done
[[ "$strategy" == "mps" ]] && kubectl -n gpu-operator get pods | grep -i mps || true
echo ">> Done: tables are now on $strategy"
