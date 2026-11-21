#!/usr/bin/env bash
# 03-join.sh: LIVE. Add one more GPU VM to the cluster.   ./scripts/demo/03-join.sh h200-2
set -euo pipefail
source "$(dirname "$0")/lib.sh"
N="${1:?usage: $0 <vm-name>}"
TSIP=$(on "$N" "tailscale ip -4")
on "$N" "systemctl is-active --quiet k3s-agent || curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION='${K3S_VERSION:-}' \
  K3S_URL='https://$(cat "$DEMO_DIR/out/cp-tailscale-ip"):6443' K3S_TOKEN='$(cat "$DEMO_DIR/out/token")' sh -s - agent \
  --default-runtime nvidia --node-ip $TSIP --flannel-iface tailscale0 \
  --node-label workshop.devfest/gpu=true --node-label workshop.devfest/table=$N" >/dev/null
REF="$BASE_IMAGE"; [[ "$REF" == */*/* ]] || REF="docker.io/$REF"
on "$N" "nohup k3s ctr images pull $REF >/var/log/workshop-image-pull.log 2>&1 </dev/null &"
kubectl wait --for=condition=Ready node/"$N" --timeout=180s >/dev/null 2>&1 || true
kubectl get nodes -o wide
