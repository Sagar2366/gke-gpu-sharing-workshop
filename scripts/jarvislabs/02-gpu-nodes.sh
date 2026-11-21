#!/usr/bin/env bash
# 02-gpu-nodes.sh: LIVE step. Join every GPU VM to k3s and load the workshop image.
#
# Fast because prep-hosts.sh already installed the driver and toolkit, built the image
# tarball and cached Gemma. Runs on all VMs in parallel (~2-4 min).
#
#   ./scripts/jarvislabs/02-gpu-nodes.sh
set -euo pipefail
cd "$(dirname "$0")"
source ./jl.conf
TOKEN=$(cat out/node-token)
mkdir -p out/logs

join () {  # ip
  ssh -i "$SSH_KEY" -o StrictHostKeyChecking=accept-new "${SSH_USER}@$1" bash -s <<EOF
set -euo pipefail
nvidia-smi -L >/dev/null || { echo "no NVIDIA driver: run prep-hosts.sh first"; exit 1; }
command -v nvidia-container-runtime >/dev/null || { echo "no NVIDIA container toolkit: run prep-hosts.sh first"; exit 1; }
[ -f /var/lib/workshop/lab-image.tar ] || { echo "no /var/lib/workshop/lab-image.tar: run prep-hosts.sh first"; exit 1; }

if systemctl is-active --quiet k3s; then
  echo "solo mode: this VM is the k3s server, no agent needed"
elif ! systemctl is-active --quiet k3s-agent; then
  curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION='${K3S_VERSION}' K3S_URL='https://${SERVER_PRIVATE_IP}:6443' K3S_TOKEN='${TOKEN}' \
    sh -s - agent --default-runtime nvidia
fi
for i in \$(seq 1 30); do [ -S /run/k3s/containerd/containerd.sock ] && break; sleep 2; done
k3s ctr images ls -q | grep -q 'workshop/lab-image:planb' || k3s ctr images import /var/lib/workshop/lab-image.tar >/dev/null
echo JOINED
EOF
}

start=$(date +%s)
echo "$GPU_NODES" | while read -r ip table role; do
  [[ -z "$ip" ]] && continue
  ( join "$ip" > "out/logs/join-${ip}.log" 2>&1 && echo "OK    $ip ($role $table) joined" \
      || echo "FAIL  $ip ($role $table): $(tail -1 out/logs/join-${ip}.log)" ) &
done
wait

export KUBECONFIG="$PWD/out/admin.kubeconfig"
kubectl get nodes -o wide
echo "joined in $(( $(date +%s) - start ))s. Next: ./scripts/jarvislabs/03-platform.sh"
