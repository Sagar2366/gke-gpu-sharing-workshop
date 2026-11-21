# lib.sh: shared helpers for the Jarvislabs scripts (sourced, not run).

ip_to_node () {  # map an SSH IP to the k8s node name
  kubectl get nodes -o jsonpath="{range .items[*]}{.metadata.name}{' '}{.status.addresses[*].address}{'\n'}{end}" \
    | awk -v ip="$1" '$0 ~ ip {print $1; exit}'
}

# set_gpu_mode <node> <exclusive|ts|mps|hami>
#   exclusive  NVIDIA device plugin, no sharing: 1 GPU = 1 pod           (the default problem)
#   ts         NVIDIA device plugin, time-slicing with 4 replicas
#   mps        NVIDIA device plugin, MPS with 4 shares
#   hami       NVIDIA device plugin OFF on this node, HAMi's device plugin ON
# Also keeps GKE-style labels in sync, so manifests written for GKE still work.
set_gpu_mode () {
  local node=$1 mode=$2
  unlabel () { kubectl label node "$node" "$@" >/dev/null 2>&1 || true; }   # removing a missing label is fine
  case "$mode" in
    exclusive)
      kubectl label node "$node" --overwrite >/dev/null \
        workshop.devfest/gpu-mode=exclusive nvidia.com/device-plugin.config=none nvidia.com/gpu.deploy.device-plugin=true
      unlabel gpu- cloud.google.com/gke-gpu-sharing-strategy- cloud.google.com/gke-max-shared-clients-per-gpu- ;;
    ts)
      kubectl label node "$node" --overwrite >/dev/null \
        workshop.devfest/gpu-mode=time-sharing nvidia.com/device-plugin.config=ts4 nvidia.com/gpu.deploy.device-plugin=true \
        cloud.google.com/gke-gpu-sharing-strategy=time-sharing cloud.google.com/gke-max-shared-clients-per-gpu=4
      unlabel gpu- ;;
    mps)
      kubectl label node "$node" --overwrite >/dev/null \
        workshop.devfest/gpu-mode=mps nvidia.com/device-plugin.config=mps4 nvidia.com/gpu.deploy.device-plugin=true \
        cloud.google.com/gke-gpu-sharing-strategy=mps cloud.google.com/gke-max-shared-clients-per-gpu=4
      unlabel gpu- ;;
    hami)
      kubectl label node "$node" --overwrite >/dev/null \
        workshop.devfest/gpu-mode=hami nvidia.com/gpu.deploy.device-plugin=false gpu=on
      unlabel cloud.google.com/gke-gpu-sharing-strategy- cloud.google.com/gke-max-shared-clients-per-gpu- ;;
    *) echo "unknown mode $mode (exclusive|ts|mps|hami)"; return 1 ;;
  esac
}

expected_slots () {  # mode -> nvidia.com/gpu per node
  case "$1" in exclusive) echo 1 ;; ts|mps) echo 4 ;; hami) echo "${HAMI_SPLIT:-10}" ;; esac
}

wait_for_slots () {  # <expected> <node...>
  local want=$1; shift
  for _ in $(seq 1 40); do
    local ready=0 total=0
    for n in "$@"; do
      total=$((total+1))
      [[ "$(kubectl get node "$n" -o jsonpath='{.status.allocatable.nvidia\.com/gpu}')" == "$want" ]] && ready=$((ready+1))
    done
    echo "   $ready/$total nodes show nvidia.com/gpu: $want"
    [[ $ready == "$total" ]] && return 0
    sleep 10
  done
  return 1
}
