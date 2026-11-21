#!/usr/bin/env bash
# demo.sh: the instructor's on-screen demos for "NVIDIA's answers: MPS and MIG".
#
#   ./scripts/jarvislabs/demo.sh mps     # 4 burn pods on the stage GPU in MPS mode; watch speeds stay steady
#   ./scripts/jarvislabs/demo.sh mig     # probe + burn + memhog on MIG slices of the big GPU
#   ./scripts/jarvislabs/demo.sh clean   # delete the demo namespace
#
# Before "mps": ROLE=stage ./scripts/jarvislabs/04-switch-strategy.sh mps
set -euo pipefail
cd "$(dirname "$0")"
source ./jl.conf
source ../../workshop.conf
export KUBECONFIG="$PWD/out/admin.kubeconfig"
NS=demo

setup_ns () {
  kubectl create namespace $NS --dry-run=client -o yaml | kubectl apply -f - >/dev/null
  kubectl -n $NS create configmap gpu-scripts --from-file=../../workloads/probe.py --from-file=../../workloads/burn.py \
    --from-file=../../workloads/memhog.py --dry-run=client -o yaml | kubectl apply -f - >/dev/null
}

pod () {  # name selector-yaml command hostipc extra-env
  kubectl -n $NS delete pod "$1" --ignore-not-found --wait=true >/dev/null
  kubectl -n $NS apply -f - >/dev/null <<EOF
apiVersion: v1
kind: Pod
metadata: {name: $1, labels: {app: demo}}
spec:
  restartPolicy: Never
  hostIPC: $4
  nodeSelector: {$2}
  containers:
  - name: c
    image: ${IMAGE}
    command: $3
    env: [{name: GIB, value: "${MIG_MEMHOG_GIB}"}]
    resources: {limits: {nvidia.com/gpu: 1}}
    volumeMounts: [{name: scripts, mountPath: /scripts}]
  volumes: [{name: scripts, configMap: {name: gpu-scripts}}]
EOF
}

follow () {  # tail several pods' logs side by side, prefixed
  for p in "$@"; do (kubectl -n $NS logs -f "$p" 2>/dev/null | sed "s/^/[$p] /") & done
  echo ">> Ctrl+C to stop watching"; wait
}

case "${1:-}" in
  mps)
    setup_ns
    sel='workshop.devfest/role: stage, workshop.devfest/gpu-mode: mps'
    pod mps-1 "$sel" '["python3","/scripts/burn.py"]' true
    echo ">> One pod alone for 30 s..."; sleep 30; kubectl -n $NS logs mps-1 | tail -2
    for i in 2 3 4; do pod mps-$i "$sel" '["python3","/scripts/burn.py"]' true; done
    echo ">> Now four pods. Watch mps-1: it stays about the same."
    follow mps-1 mps-2 mps-3 mps-4 ;;
  mig)
    setup_ns
    sel='workshop.devfest/role: mig'
    pod mig-probe "$sel" '["bash","-c","nvidia-smi -L; python3 /scripts/probe.py"]' false
    sleep 25; kubectl -n $NS logs mig-probe
    pod mig-memhog "$sel" '["python3","/scripts/memhog.py"]' false
    for i in 1 2 3; do pod mig-burn-$i "$sel" '["python3","/scripts/burn.py"]' false; done
    echo ">> memhog hits its own slice's wall; the burn pods' speeds stay flat."
    follow mig-memhog mig-burn-1 mig-burn-2 mig-burn-3 ;;
  clean)
    kubectl delete namespace $NS --wait=false ;;
  *) echo "usage: $0 mps|mig|clean"; exit 1 ;;
esac
