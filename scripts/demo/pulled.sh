#!/usr/bin/env bash
# pulled.sh: has the big workshop image finished downloading on every VM?
set -uo pipefail
source "$(dirname "$0")/lib.sh"
for n in $(all_vms); do printf "%-8s " "$n"; on "$n" "crictl images 2>/dev/null | grep -q vllm && echo ready || (tail -c 160 /var/log/workshop-image-pull.log 2>/dev/null | tr '\r' '\n' | tail -1)"; done
