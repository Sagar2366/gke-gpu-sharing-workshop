#!/usr/bin/env bash
# control-plane.sh: (instructor) the k3s control plane, run INSIDE an Ubuntu VM on your laptop.
# mac-up.sh copies the repo in and runs this for you. It:
#   1. joins the VM to your Tailscale network (so the GPU VMs in the data centre can reach it)
#   2. installs the k3s server, using the Tailscale interface for node and pod traffic
set -euo pipefail
: "${TS_AUTHKEY:?}"
command -v tailscale >/dev/null || curl -fsSL https://tailscale.com/install.sh | sh
tailscale up --authkey "$TS_AUTHKEY" --hostname k3s-cp >/dev/null
TSIP=$(tailscale ip -4)
LANIP=$(hostname -I | awk '{print $1}')
if ! systemctl is-active --quiet k3s; then
  curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="${K3S_VERSION:-}" sh -s - server \
    --node-ip "$TSIP" --flannel-iface tailscale0 \
    --tls-san "$TSIP" --tls-san "$LANIP" \
    --write-kubeconfig-mode 644 --disable traefik \
    --node-label workshop.devfest/pool=system
fi
echo "TSIP=$TSIP"
echo "LANIP=$LANIP"
