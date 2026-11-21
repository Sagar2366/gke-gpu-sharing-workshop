#!/usr/bin/env bash
# 03-gpu-operator.sh: LIVE step. Teach Kubernetes about the GPUs.
#
# Before this step `kubectl describe node` shows NO nvidia.com/gpu, even though nvidia-smi works on the
# machine: Kubernetes doesn't know about GPUs until a *device plugin* tells it. This installs NVIDIA's
# GPU Operator (device plugin, DCGM exporter, MIG manager), labels and taints the GPU nodes, and starts
# every table GPU in INITIAL_MODE:
#
#   INITIAL_MODE=exclusive  (default) one GPU = one pod, the "default allocation" problem
#   INITIAL_MODE=ts         time-slicing from the start (older flow)
#
#   ./scripts/jarvislabs/03-gpu-operator.sh
set -euo pipefail
cd "$(dirname "$0")"
source ./jl.conf
source ./lib.sh
export KUBECONFIG="$PWD/out/admin.kubeconfig"
MODE="${INITIAL_MODE:-exclusive}"

echo ">> NVIDIA GPU Operator"
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia >/dev/null 2>&1 || true
helm repo update nvidia >/dev/null
kubectl create namespace gpu-operator --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl apply -f device-plugin-config.yaml >/dev/null
helm upgrade --install gpu-operator nvidia/gpu-operator -n gpu-operator \
  ${GPU_OPERATOR_VERSION:+--version "$GPU_OPERATOR_VERSION"} \
  --set driver.enabled=false \
  --set toolkit.enabled=false \
  --set devicePlugin.config.name=device-plugin-config \
  --set devicePlugin.config.default=none \
  --set mig.strategy=single \
  --set migManager.enabled=true \
  --set dcgmExporter.serviceMonitor.enabled=true \
  --wait --timeout 15m

echo ">> Labels and taints (table GPUs start in mode: $MODE)"
echo "$GPU_NODES" | while read -r ip table role; do
  [[ -z "$ip" ]] && continue
  node=$(ip_to_node "$ip"); [[ -z "$node" ]] && { echo "!! no node for $ip"; continue; }
  solo=0; [[ "$ip" == "$SERVER_PUBLIC_IP" ]] && solo=1
  # Solo mode: the one VM also runs system pods, so no taint and it keeps pool=system.
  [[ $solo == 0 ]] && kubectl taint node "$node" nvidia.com/gpu=present:NoSchedule --overwrite >/dev/null
  pool="planb-$role"; [[ $solo == 1 ]] && pool=system
  kubectl label node "$node" --overwrite >/dev/null workshop.devfest/role="$role" workshop.devfest/pool="$pool"
  case "$role" in
    table|stage)
      kubectl label node "$node" --overwrite >/dev/null workshop.devfest/table="$table" cloud.google.com/gke-accelerator="$TABLE_GPU_LABEL"
      set_gpu_mode "$node" "$MODE"
      echo "   $role $table -> $node ($MODE)" ;;
    mig)
      kubectl label node "$node" --overwrite >/dev/null \
        workshop.devfest/gpu-mode=mig cloud.google.com/gke-accelerator="$MIG_GPU_LABEL" \
        nvidia.com/device-plugin.config=mig nvidia.com/mig.config="$MIG_CONFIG" cloud.google.com/gke-gpu-partition-size="$MIG_PROFILE"
      echo "   mig ${MIG_CONFIG} -> $node (MIG manager reconfigures the GPU; takes a few minutes)" ;;
  esac
done

mapfile -t nodes < <(kubectl get nodes -l workshop.devfest/role=table -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')
wait_for_slots "$(expected_slots "$MODE")" "${nodes[@]}" || echo "!! some nodes not ready yet; check ./status.sh"

kubectl get nodes -l cloud.google.com/gke-accelerator -o custom-columns='NODE:.metadata.name,TABLE:.metadata.labels.workshop\.devfest/table,MODE:.metadata.labels.workshop\.devfest/gpu-mode,GPU:.status.allocatable.nvidia\.com/gpu'
