#!/usr/bin/env bash
# 03-platform.sh: turn the k3s cluster into a "GKE-shaped" GPU cluster.
#
#   - NVIDIA GPU Operator (driver + toolkit already on the hosts, from 02)
#     with per-node device plugin configs: none / ts4 / mps4 / mig
#   - GKE-compatible node labels, so the lab manifests run unchanged:
#       cloud.google.com/gke-accelerator, cloud.google.com/gke-gpu-sharing-strategy,
#       cloud.google.com/gke-max-shared-clients-per-gpu, cloud.google.com/gke-gpu-partition-size,
#       workshop.devfest/table
#   - the nvidia.com/gpu=present:NoSchedule taint (like GKE)
#   - kube-prometheus-stack + DCGM dashboard (stands in for Cloud Monitoring)
#
# Usage: ./scripts/jarvislabs/03-platform.sh
set -euo pipefail
cd "$(dirname "$0")"
source ./jl.conf
export KUBECONFIG="$PWD/out/admin.kubeconfig"

ip_to_node () {  # map an SSH IP to the k8s node name
  kubectl get nodes -o jsonpath="{range .items[*]}{.metadata.name}{' '}{.status.addresses[*].address}{'\n'}{end}" \
    | awk -v ip="$1" '$0 ~ ip {print $1; exit}'
}

echo ">> 1/4  GPU Operator"
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia >/dev/null 2>&1 || true
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update >/dev/null
kubectl create namespace gpu-operator --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f device-plugin-config.yaml
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

echo ">> 2/4  Labels and taints"
echo "$GPU_NODES" | while read -r ip table role; do
  [[ -z "$ip" ]] && continue
  node=$(ip_to_node "$ip"); [[ -z "$node" ]] && { echo "!! no node for $ip"; continue; }
  solo=0; [[ "$ip" == "$SERVER_PUBLIC_IP" ]] && solo=1
  # In solo mode the GPU node also runs the system pods, so it isn't tainted and keeps pool=system.
  [[ $solo == 0 ]] && kubectl taint node "$node" nvidia.com/gpu=present:NoSchedule --overwrite >/dev/null
  pool_label="workshop.devfest/pool=planb-$role"; [[ $solo == 1 ]] && pool_label="workshop.devfest/pool=system"
  kubectl label node "$node" workshop.devfest/role="$role" --overwrite >/dev/null
  case "$role" in
    table|stage)
      kubectl label node "$node" --overwrite >/dev/null \
        workshop.devfest/table="$table" "$pool_label" \
        cloud.google.com/gke-accelerator="$TABLE_GPU_LABEL" \
        nvidia.com/device-plugin.config=ts4 \
        cloud.google.com/gke-gpu-sharing-strategy=time-sharing \
        cloud.google.com/gke-max-shared-clients-per-gpu=4
      echo "$role  $table  time-sharing  -> $node" ;;
    mig)
      kubectl label node "$node" --overwrite >/dev/null \
        "$pool_label" \
        cloud.google.com/gke-accelerator="$MIG_GPU_LABEL" \
        nvidia.com/device-plugin.config=mig \
        nvidia.com/mig.config="$MIG_CONFIG" \
        cloud.google.com/gke-gpu-partition-size="$MIG_PROFILE"
      echo "mig   ${MIG_CONFIG}  -> $node   (mig-manager will reconfigure the GPU; can take a few minutes)" ;;
  esac
done

echo ">> 3/4  Monitoring (Prometheus + Grafana + DCGM dashboard)"
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack -n monitoring --create-namespace \
  -f monitoring-values.yaml --wait --timeout 15m

echo ">> 4/4  Waiting for shared GPUs to show 4 slots"
for i in $(seq 1 30); do
  kubectl get nodes -l cloud.google.com/gke-accelerator \
    -o custom-columns='NODE:.metadata.name,TABLE:.metadata.labels.workshop\.devfest/table,STRATEGY:.metadata.labels.cloud\.google\.com/gke-gpu-sharing-strategy,PARTITION:.metadata.labels.cloud\.google\.com/gke-gpu-partition-size,GPU:.status.allocatable.nvidia\.com/gpu'
  pending=$(kubectl get nodes -l cloud.google.com/gke-gpu-sharing-strategy -o jsonpath='{range .items[*]}{.status.allocatable.nvidia\.com/gpu}{"\n"}{end}' | grep -vc '^4$' || true)
  [[ "$pending" == "0" ]] && break
  sleep 20; echo
done

cat <<EOF

>> Platform ready.
   Grafana   : http://${SERVER_PUBLIC_IP}:30300   (anonymous read-only; admin password in monitoring-values.yaml)
   Prometheus: http://${SERVER_PUBLIC_IP}:30090
   Next      : ./06-onboard.sh "$ATTENDEES_CSV" && ./07-serve-kubeconfigs.sh   (up.sh does this for you)
EOF
