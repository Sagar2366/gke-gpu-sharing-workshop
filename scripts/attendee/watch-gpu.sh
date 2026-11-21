#!/usr/bin/env bash
# watch-gpu.sh: print duty cycle and memory used for GPU nodes from Cloud Monitoring,
# using the PromQL API. Refreshes every 30 s. Ctrl-C to stop.
#
#   bash scripts/attendee/watch-gpu.sh            # your table's nodes
#   bash scripts/attendee/watch-gpu.sh all        # every GPU node in the cluster
#
# Note: system metrics are sampled every 60 s and can lag 2-3 minutes.
set -euo pipefail
source "$(dirname "$0")/../../workshop.conf"
[[ -f "$HOME/.gpu-workshop-env" ]] && source "$HOME/.gpu-workshop-env"

if [[ "${1:-}" == "all" || -z "${TABLE:-}" ]]; then
  nodes='.*'
else
  nodes=$(kubectl get nodes -l "${TABLE_LABEL}=${TABLE}" -o jsonpath='{.items[*].metadata.name}' | tr ' ' '|')
fi

if [[ "$PLATFORM" == "jarvislabs" ]]; then
  # Plan B: query the in-cluster Prometheus (DCGM exporter metrics), no auth.
  # DCGM's Hostname label is the exporter pod's host, which may not match the k8s node
  # name, so we show every GPU and let you spot yours (see the Plan B page for Grafana).
  api="${PROM_URL}/api/v1/query"
  q () { curl -s "$api" --data-urlencode "query=$1" |
         jq -r '.data.result[] | "\(.metric.Hostname)\t\(.value[1] | tonumber | . * 10 | round / 10)"'; }
  UTIL="max by (Hostname) (DCGM_FI_DEV_GPU_UTIL)"
  MEM="max by (Hostname) (DCGM_FI_DEV_FB_USED) / 1024"
else
  api="https://monitoring.googleapis.com/v1/projects/${WORKSHOP_PROJECT}/location/global/prometheus/api/v1/query"
  q () { curl -s -X POST "$api" -H "Authorization: Bearer $(gcloud auth print-access-token)" --data-urlencode "query=$1" |
         jq -r '.data.result[] | "\(.metric.node_name)\t\(.value[1] | tonumber | . * 10 | round / 10)"'; }
  UTIL="max by (node_name) (kubernetes_io:node_accelerator_duty_cycle{monitored_resource=\"k8s_node\",cluster_name=\"${CLUSTER}\",node_name=~\"${nodes}\"})"
  MEM="max by (node_name) (kubernetes_io:node_accelerator_memory_used{monitored_resource=\"k8s_node\",cluster_name=\"${CLUSTER}\",node_name=~\"${nodes}\"}) / 1024^3"
fi

while true; do
  clear
  date
  echo "--- GPU busy % (last sample)"
  q "$UTIL" | column -t
  echo "--- GPU memory used GiB"
  q "$MEM" | column -t
  sleep 30
done
