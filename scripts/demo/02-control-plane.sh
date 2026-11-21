#!/usr/bin/env bash
# 02-control-plane.sh: LIVE. Start Kubernetes (k3s) on the first VM and point your laptop's kubectl at it.
set -euo pipefail
source "$(dirname "$0")/lib.sh"
CP=$(first_vm)
TSIP=$(on "$CP" "tailscale ip -4")
on "$CP" "systemctl is-active --quiet k3s || curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION='${K3S_VERSION:-}' sh -s - server \
  --default-runtime nvidia --disable traefik --write-kubeconfig-mode 644 \
  --node-ip $TSIP --flannel-iface tailscale0 --tls-san $TSIP --tls-san $(vm_ip "$CP") \
  --node-label workshop.devfest/gpu=true --node-label workshop.devfest/table=$CP" >/dev/null
on "$CP" "cat /var/lib/rancher/k3s/server/node-token" > "$DEMO_DIR/out/token"
echo "$TSIP" > "$DEMO_DIR/out/cp-tailscale-ip"
HOST=$(vm_ip "$CP"); [[ "$API_VIA" == "tailscale" ]] && HOST=$TSIP
on "$CP" "cat /etc/rancher/k3s/k3s.yaml" | sed "s/127.0.0.1/$HOST/" > "$KUBECONFIG"; chmod 600 "$KUBECONFIG"
for i in $(seq 1 30); do kubectl get nodes >/dev/null 2>&1 && break; sleep 2; done
kubectl create configmap gpu-scripts --from-file="$ROOT/workloads/probe.py" --from-file="$ROOT/workloads/burn.py" \
  --from-file="$ROOT/workloads/memhog.py" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl create secret generic hf-token --from-literal=token="${HF_TOKEN:-none}" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
REF="$BASE_IMAGE"; [[ "$REF" == */*/* ]] || REF="docker.io/$REF"
on "$CP" "nohup k3s ctr images pull $REF >/var/log/workshop-image-pull.log 2>&1 </dev/null &"
kubectl get nodes -o wide
echo ">> In every new terminal:  export KUBECONFIG=$KUBECONFIG"
