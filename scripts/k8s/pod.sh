#!/usr/bin/env bash
# pod.sh: start the workshop's demo pods with one short command (they're plain YAML; add --show to print it).
#
#   ./scripts/k8s/pod.sh burn-cpu                 # the matrix work on CPU only (no GPU requested)
#   ./scripts/k8s/pod.sh burn-gpu                 # the same work, asking for nvidia.com/gpu: 1
#   ./scripts/k8s/pod.sh hold dosa idli vada chai # pods that just hold a GPU (any node)
#   ./scripts/k8s/pod.sh burn dosa [idli ...]     # GPU-hungry job, prints TFLOPS   (pod burn-<team>)
#   ./scripts/k8s/pod.sh memhog idli 130          # grab 130 GiB of GPU memory       (pod memhog-<team>)
#   ./scripts/k8s/pod.sh probe                    # print what the GPU looks like from inside
#   ./scripts/k8s/pod.sh greedy                   # asks for 2 shared GPUs (the gotcha)
#   ./scripts/k8s/pod.sh hami-memhog idli 40      # memhog with a HAMi limit of 20 GB / 25%
#
# Pods go to the node in $TABLE (e.g. export TABLE=h200-1), except "hold".
# On an MPS node, pods automatically get hostIPC: true (MPS needs it).
set -euo pipefail
: "${IMAGE:?source scripts/demo/env.sh first}"
SHOW=0; args=()
for a in "$@"; do [[ "$a" == "--show" ]] && SHOW=1 || args+=("$a"); done
if [[ ${#args[@]} -gt 0 ]]; then set -- "${args[@]}"; else set --; fi
KIND="${1:?usage: see the top of $0}"; shift || true

node_sel () { [[ -n "${TABLE:-}" ]] && echo "  nodeSelector: {workshop.devfest/table: $TABLE}"; }
host_ipc () {
  [[ -n "${TABLE:-}" ]] || { echo "false"; return; }
  [[ "$(kubectl get node "$TABLE" -o jsonpath='{.metadata.labels.workshop\.devfest/gpu-mode}' 2>/dev/null)" == "mps" ]] && echo true || echo false
}

emit () {  # name labels-app restart hostipc selector command env-yaml limits
  cat <<EOF
apiVersion: v1
kind: Pod
metadata: {name: $1, labels: {app: $2}}
spec:
  restartPolicy: $3
  hostIPC: $4
$5
  containers:
  - name: main
    image: $IMAGE
    command: $6
    env: $7
    resources: {limits: $8}
    volumeMounts: [{name: scripts, mountPath: /scripts}]
  volumes: [{name: scripts, configMap: {name: gpu-scripts}}]
EOF
}

run () { if [[ $SHOW == 1 ]]; then emit "$@"; echo "---"; else emit "$@" | kubectl apply -f -; fi; }

GPU1='{nvidia.com/gpu: 1}'
case "$KIND" in
  burn-cpu) run burn-cpu burn Never false "$(node_sel)" '["python3", "/scripts/burn.py"]' '[{name: DEVICE, value: cpu}]' '{memory: 8Gi}' ;;
  burn-gpu) run burn-gpu burn Never false "$(node_sel)" '["python3", "/scripts/burn.py"]' '[]' "$GPU1" ;;
  probe)    run probe probe Never "$(host_ipc)" "$(node_sel)" '["bash", "-c", "nvidia-smi -L; python3 /scripts/probe.py"]' '[]' "$GPU1" ;;
  greedy)   run greedy greedy Never false "$(node_sel)" '["sleep", "60"]' '[]' '{nvidia.com/gpu: 2}' ;;
  hold)     for t in "$@"; do run "hold-$t" hold Always false "" '["sleep", "infinity"]' '[]' "$GPU1"; done ;;
  burn)     ipc=$(host_ipc); for t in "$@"; do run "burn-$t" burn Always "$ipc" "$(node_sel)" '["python3", "/scripts/burn.py"]' "[{name: MATRIX, value: \"${MATRIX:-8192}\"}]" "$GPU1"; done ;;
  memhog)   gib="${*: -1}"; ipc=$(host_ipc)
            for t in "${@:1:$#-1}"; do run "memhog-$t" memhog Always "$ipc" "$(node_sel)" '["python3", "/scripts/memhog.py"]' "[{name: GIB, value: \"$gib\"}]" "$GPU1"; done ;;
  hami-memhog) gib="${*: -1}"
            for t in "${@:1:$#-1}"; do run "memhog-$t" memhog Always false "$(node_sel)" '["python3", "/scripts/memhog.py"]' "[{name: GIB, value: \"$gib\"}]" '{nvidia.com/gpu: 1, nvidia.com/gpumem: 20000, nvidia.com/gpucores: 25}'; done ;;
  *) echo "unknown kind '$KIND' (see the top of $0)"; exit 1 ;;
esac
