#!/usr/bin/env bash
# k3s-single.sh: turn THIS GPU VM into a one-node Kubernetes cluster. Run ON the VM, as root:
#
#   sudo ./scripts/node/k3s-single.sh
#
# Installs k3s (a small, certified Kubernetes) with NVIDIA's container runtime as the default, so
# containers can reach the GPU. Note what it does NOT do: tell Kubernetes about the GPU. That's the
# device plugin, a later step. Also starts pulling the workshop image in the background.
set -euo pipefail
cd "$(dirname "$0")/../.."
source ./workshop.conf
[[ $EUID -eq 0 ]] || { echo "run as root: sudo $0"; exit 1; }
command -v nvidia-container-runtime >/dev/null || { echo "!! run ./scripts/node/prep.sh first"; exit 1; }

if ! systemctl is-active --quiet k3s; then
  curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="${K3S_VERSION:-}" sh -s - server \
    --default-runtime nvidia \
    --write-kubeconfig-mode 644 \
    --disable traefik \
    --node-label workshop.devfest/gpu=true \
    --node-label workshop.devfest/table=me
fi
mkdir -p ~/.kube && cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
export KUBECONFIG=~/.kube/config
for i in $(seq 1 30); do kubectl get nodes >/dev/null 2>&1 && break; sleep 2; done
kubectl wait --for=condition=Ready node --all --timeout=120s >/dev/null

# The lab scripts, as a ConfigMap the pods mount
kubectl create configmap gpu-scripts --from-file=workloads/probe.py --from-file=workloads/burn.py \
  --from-file=workloads/memhog.py --dry-run=client -o yaml | kubectl apply -f - >/dev/null

# Start the big image download now, so it's ready when we need it (~10 GB)
REF="$IMAGE"; [[ "$REF" == */*/* ]] || REF="docker.io/$REF"
( k3s ctr images pull "$REF" >/var/log/workshop-image-pull.log 2>&1 && echo done >> /var/log/workshop-image-pull.log ) &

kubectl get nodes -o wide
echo ">> Your cluster is up (image downloading in the background: tail /var/log/workshop-image-pull.log)."
echo ">> Next: source scripts/node/env.sh"
