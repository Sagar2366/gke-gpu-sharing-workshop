#!/usr/bin/env bash
# 02-label-tables.sh: give every L4 node a table id (t01, t02, ...).
#
# Table t07's four attendees all land on the t07 time-sharing node in Lab 2
# and on the t07 MPS node in Lab 4: four teams, one GPU.
# Re-run this any time a node is recreated (auto-repair, resize).
set -euo pipefail
cd "$(dirname "$0")/../.."
source ./workshop.conf

# STAGE=1: reserve the FIRST time-sharing node as table t00, the instructor's
# stage GPU for the Astronomy Shop finale. Attendee tables then start at t01.
for pool in "$TS_POOL" "$MPS_POOL"; do
  i=1
  stage_pending=0; [[ "${STAGE:-0}" == "1" && "$pool" == "$TS_POOL" ]] && stage_pending=1
  for node in $(kubectl get nodes -l "cloud.google.com/gke-nodepool=${pool}" \
                  -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | sort); do
    if [[ $stage_pending == 1 ]]; then
      kubectl label node "$node" "${TABLE_LABEL}=t00" --overwrite >/dev/null
      echo "$pool  t00 (stage) ->  $node"; stage_pending=0; continue
    fi
    table=$(printf "t%02d" "$i")
    kubectl label node "$node" "${TABLE_LABEL}=${table}" --overwrite >/dev/null
    echo "$pool  $table  ->  $node"
    i=$((i + 1))
  done
done

echo
kubectl get nodes -L "${TABLE_LABEL},cloud.google.com/gke-gpu-sharing-strategy,cloud.google.com/gke-gpu-partition-size" \
  -l cloud.google.com/gke-accelerator
