#!/usr/bin/env bash
# 04-switch-strategy.sh: LIVE step. Change how every table GPU is shared, in front of the room.
#
#   ./scripts/jarvislabs/04-switch-strategy.sh exclusive   # 1 GPU = 1 pod       (the default problem)
#   ./scripts/jarvislabs/04-switch-strategy.sh ts          # time-slicing, 4 slots
#   ./scripts/jarvislabs/04-switch-strategy.sh mps         # NVIDIA MPS, 4 shares
#   ./scripts/jarvislabs/04-switch-strategy.sh hami        # HAMi: ask for GB of memory and % of compute
#
#   ROLE=stage ./04-switch-strategy.sh mps   # only the stage GPU (for the MPS demo)
#
# It's just node labels: NVIDIA's device plugin picks a new config (or steps aside for HAMi).
# Attendee pods still on the table GPUs are deleted first. Takes ~1-2 min.
set -euo pipefail
cd "$(dirname "$0")"
source ./jl.conf
source ./lib.sh
export KUBECONFIG="$PWD/out/admin.kubeconfig"
MODE="${1:?usage: $0 exclusive|ts|mps|hami}"
ROLE="${ROLE:-table}"

[[ "$MODE" == "hami" ]] && ./05-install-hami.sh

mapfile -t nodes < <(kubectl get nodes -l workshop.devfest/role="$ROLE" -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')
echo ">> Switching ${#nodes[@]} ${ROLE} GPU(s) to: $MODE"
for n in "${nodes[@]}"; do
  kubectl get pods -A --field-selector spec.nodeName="$n" \
    -o jsonpath='{range .items[*]}{.metadata.namespace}{" "}{.metadata.name}{"\n"}{end}' \
    | grep -E '^t[0-9]+-' | while read -r ns pod; do kubectl -n "$ns" delete pod "$pod" --wait=false >/dev/null; done || true
  set_gpu_mode "$n" "$MODE"
done

wait_for_slots "$(expected_slots "$MODE")" "${nodes[@]}" || echo "!! not all nodes ready yet; check ./status.sh"
[[ "$MODE" == "mps" ]] && kubectl -n gpu-operator get pods | grep -i mps || true
echo ">> Done: ${ROLE} GPUs are now in mode '$MODE'"
