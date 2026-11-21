#!/usr/bin/env bash
# gpu-operator.sh: tell Kubernetes about the GPUs.
#
# Before this, a node can have a working GPU and Kubernetes still shows no nvidia.com/gpu: nothing has
# ADVERTISED it. This installs NVIDIA's GPU Operator: the device plugin (advertises GPUs), GPU Feature
# Discovery (labels), the DCGM exporter (metrics) and the MIG manager. GPUs start in "exclusive" mode:
# one GPU, one pod.
#
#   ./scripts/k8s/gpu-operator.sh
set -euo pipefail
cd "$(dirname "$0")"
source ./lib.sh
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia >/dev/null 2>&1 || true
helm repo update nvidia >/dev/null
kubectl create namespace gpu-operator --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl apply -f device-plugin-config.yaml >/dev/null
nodes=(); while IFS= read -r l; do [[ -n "$l" ]] && nodes+=("$l"); done < <(gpu_nodes)
for n in "${nodes[@]}"; do set_gpu_mode "$n" exclusive; done
echo ">> Installing the NVIDIA GPU Operator (2-4 minutes)"
helm upgrade --install gpu-operator nvidia/gpu-operator -n gpu-operator \
  ${GPU_OPERATOR_VERSION:+--version "$GPU_OPERATOR_VERSION"} \
  --set driver.enabled=false --set toolkit.enabled=false \
  --set devicePlugin.config.name=device-plugin-config --set devicePlugin.config.default=none \
  --set mig.strategy=single --set migManager.enabled=true \
  --wait --timeout 15m >/dev/null
wait_for_slots 1 "${nodes[@]}" || echo "!! not ready yet: kubectl get pods -n gpu-operator"
show_gpus
