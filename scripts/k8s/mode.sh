#!/usr/bin/env bash
# mode.sh: change how the GPU(s) are shared. It's only node labels.
#
#   ./scripts/k8s/mode.sh exclusive   # 1 GPU = 1 pod (Kubernetes' default)
#   ./scripts/k8s/mode.sh ts          # time-slicing: 4 pods take turns
#   ./scripts/k8s/mode.sh mps         # NVIDIA MPS: 4 pods run together, each capped at ~1/4
#   ./scripts/k8s/mode.sh hami        # HAMi: pods ask for MB of memory and % of compute
#   ./scripts/k8s/mode.sh mig         # MIG: cut the GPU into 7 hardware slices (H100/H200/A100)
#
#   NODE=<name> ./scripts/k8s/mode.sh ts    # only one node
#
# Delete your GPU pods first: a running pod keeps the old setup until it's recreated.
set -euo pipefail
cd "$(dirname "$0")"
source ./lib.sh
MODE="${1:?usage: $0 exclusive|ts|mps|hami|mig}"
[[ "$MODE" == "hami" ]] && ./hami-install.sh
nodes=(); while IFS= read -r l; do [[ -n "$l" ]] && nodes+=("$l"); done < <(gpu_nodes)
echo ">> ${#nodes[@]} GPU node(s) -> $MODE"
for n in "${nodes[@]}"; do set_gpu_mode "$n" "$MODE"; done
[[ "$MODE" == "mig" ]] && echo "   (the MIG manager reconfigures the GPU; this can take a few minutes)"
wait_for_slots "$(expected_slots "$MODE")" "${nodes[@]}" || echo "!! still switching: kubectl get pods -n gpu-operator / -n kube-system"
show_gpus
