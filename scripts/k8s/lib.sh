# lib.sh: helpers shared by the scripts in scripts/k8s (sourced, not run).
# Works wherever `kubectl` reaches the cluster: on your GPU VM, or on the instructor's laptop.

gpu_nodes () {  # all nodes labelled as GPU nodes (or just $NODE if set)
  if [[ -n "${NODE:-}" ]]; then echo "$NODE"; return; fi
  kubectl get nodes -l workshop.devfest/gpu=true -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'
}

unlabel () { local n=$1; shift; kubectl label node "$n" "$@" >/dev/null 2>&1 || true; }

# set_gpu_mode <node> <exclusive|ts|mps|hami|mig>
set_gpu_mode () {
  local node=$1 mode=$2
  case "$mode" in
    exclusive) kubectl label node "$node" --overwrite >/dev/null workshop.devfest/gpu-mode=exclusive \
                 nvidia.com/device-plugin.config=none nvidia.com/gpu.deploy.device-plugin=true
               unlabel "$node" gpu- nvidia.com/mig.config- ;;
    ts)        kubectl label node "$node" --overwrite >/dev/null workshop.devfest/gpu-mode=time-sharing \
                 nvidia.com/device-plugin.config=ts4 nvidia.com/gpu.deploy.device-plugin=true
               unlabel "$node" gpu- nvidia.com/mig.config- ;;
    mps)       kubectl label node "$node" --overwrite >/dev/null workshop.devfest/gpu-mode=mps \
                 nvidia.com/device-plugin.config=mps4 nvidia.com/gpu.deploy.device-plugin=true
               unlabel "$node" gpu- nvidia.com/mig.config- ;;
    hami)      kubectl label node "$node" --overwrite >/dev/null workshop.devfest/gpu-mode=hami \
                 nvidia.com/gpu.deploy.device-plugin=false gpu=on
               unlabel "$node" nvidia.com/mig.config- ;;
    mig)       local cfg="${MIG_CONFIG:-}" part="${MIG_PARTITION:-}"
               if [[ -z "$cfg" ]]; then
                 case "$(kubectl get node "$node" -o jsonpath='{.metadata.labels.nvidia\.com/gpu\.product}')" in
                   *H200*) cfg=all-1g.18gb part=1g.18gb ;; *H100*) cfg=all-1g.10gb part=1g.10gb ;;
                   *A100*80*) cfg=all-1g.10gb part=1g.10gb ;; *A100*) cfg=all-1g.5gb part=1g.5gb ;;
                   *) echo "!! this GPU doesn't support MIG"; return 1 ;;
                 esac
               fi
               kubectl label node "$node" --overwrite >/dev/null workshop.devfest/gpu-mode=mig \
                 nvidia.com/device-plugin.config=mig nvidia.com/gpu.deploy.device-plugin=true \
                 nvidia.com/mig.config="$cfg" cloud.google.com/gke-gpu-partition-size="$part"
               unlabel "$node" gpu- ;;
    *) echo "unknown mode '$mode' (exclusive|ts|mps|hami|mig)"; return 1 ;;
  esac
}

expected_slots () { case "$1" in exclusive) echo 1 ;; ts|mps) echo 4 ;; hami) echo "${HAMI_SPLIT:-10}" ;; mig) echo 7 ;; esac; }

wait_for_slots () {  # <expected> <node...>
  local want=$1; shift
  for _ in $(seq 1 60); do
    local ready=0 total=0
    for n in "$@"; do
      total=$((total+1))
      [[ "$(kubectl get node "$n" -o jsonpath='{.status.allocatable.nvidia\.com/gpu}')" == "$want" ]] && ready=$((ready+1))
    done
    printf "\r   %d/%d node(s) show nvidia.com/gpu: %s " "$ready" "$total" "$want"
    [[ $ready == "$total" ]] && { echo; return 0; }
    sleep 5
  done
  echo; return 1
}

show_gpus () {
  kubectl get nodes -l workshop.devfest/gpu=true -o custom-columns='NODE:.metadata.name,TABLE:.metadata.labels.workshop\.devfest/table,MODE:.metadata.labels.workshop\.devfest/gpu-mode,GPU:.status.allocatable.nvidia\.com/gpu'
}
