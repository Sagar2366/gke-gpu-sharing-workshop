#!/usr/bin/env bash
# join-agent.sh: (instructor) join THIS GPU VM to a cluster whose control plane is reachable over Tailscale.
# Run ON the GPU VM as root, after prep.sh:
#
#   sudo TS_AUTHKEY=tskey-... K3S_URL=https://<cp-tailscale-ip>:6443 K3S_TOKEN=<token> NODE_TABLE=h200-2 \
#        ./scripts/node/join-agent.sh
set -euo pipefail
cd "$(dirname "$0")/../.."
source ./workshop.conf
: "${TS_AUTHKEY:?}" "${K3S_URL:?}" "${K3S_TOKEN:?}" "${NODE_TABLE:=gpu-$(hostname)}"
command -v nvidia-container-runtime >/dev/null || { echo "!! run ./scripts/node/prep.sh first"; exit 1; }

command -v tailscale >/dev/null || curl -fsSL https://tailscale.com/install.sh | sh
tailscale up --authkey "$TS_AUTHKEY" --hostname "$NODE_TABLE" >/dev/null
TSIP=$(tailscale ip -4)
echo ">> Tailscale IP: $TSIP"

if ! systemctl is-active --quiet k3s-agent; then
  curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="${K3S_VERSION:-}" K3S_URL="$K3S_URL" K3S_TOKEN="$K3S_TOKEN" sh -s - agent \
    --default-runtime nvidia \
    --node-ip "$TSIP" --flannel-iface tailscale0 \
    --node-label workshop.devfest/gpu=true \
    --node-label workshop.devfest/table="$NODE_TABLE"
fi
REF="$BASE_IMAGE"; [[ "$REF" == */*/* ]] || REF="docker.io/$REF"
( k3s ctr images pull "$REF" >/var/log/workshop-image-pull.log 2>&1 ) &
echo ">> Joined as $NODE_TABLE. Check from the control plane: kubectl get nodes"
