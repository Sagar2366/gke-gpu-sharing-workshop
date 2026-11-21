#!/usr/bin/env bash
# status.sh: one-screen health check of the Plan B cluster. Keep it open on a second screen.
#   ./scripts/jarvislabs/status.sh          # once
#   WATCH=1 ./scripts/jarvislabs/status.sh  # refresh every 15 s
set -uo pipefail
cd "$(dirname "$0")"
source ./jl.conf
export KUBECONFIG="$PWD/out/admin.kubeconfig"

show () {
  echo "== Nodes"
  kubectl get nodes -o custom-columns='NODE:.metadata.name,READY:.status.conditions[?(@.type=="Ready")].status,TABLE:.metadata.labels.workshop\.devfest/table,STRATEGY:.metadata.labels.cloud\.google\.com/gke-gpu-sharing-strategy,PARTITION:.metadata.labels.cloud\.google\.com/gke-gpu-partition-size,GPU:.status.allocatable.nvidia\.com/gpu'
  echo; echo "== Platform pods not Running/Completed"
  kubectl get pods -n gpu-operator --no-headers 2>/dev/null | grep -vE 'Running|Completed' || echo "  gpu-operator: all good"
  kubectl get pods -n monitoring --no-headers 2>/dev/null | grep -vE 'Running|Completed' || echo "  monitoring: all good"
  echo; echo "== Attendee GPU pods per node"
  kubectl get pods -A -o jsonpath='{range .items[*]}{.spec.nodeName}{" "}{.metadata.namespace}{"\n"}{end}' 2>/dev/null \
    | grep -E ' t[0-9]+-' | awk '{print $1}' | sort | uniq -c | sed 's/^/  /' || true
  echo; echo "== Endpoints"
  for p in 6443 8088 30300 30090; do
    timeout 3 bash -c "</dev/tcp/${SERVER_PUBLIC_IP}/$p" 2>/dev/null && echo "  :$p  up" || echo "  :$p  DOWN"
  done
  echo "  Grafana: http://${SERVER_PUBLIC_IP}:30300"
}
if [[ "${WATCH:-0}" == "1" ]]; then while true; do clear; date; show; sleep 15; done; else show; fi
