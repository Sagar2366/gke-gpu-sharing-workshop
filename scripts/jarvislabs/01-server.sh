#!/usr/bin/env bash
# 01-server.sh: install the k3s server on the CPU VM, and copy an admin kubeconfig to this machine.
#
# Run from your laptop / Cloud Shell (it SSHes into the server):
#   cp scripts/jarvislabs/jl.conf.example scripts/jarvislabs/jl.conf   # then edit it
#   ./scripts/jarvislabs/01-server.sh
#
# Writes: scripts/jarvislabs/out/admin.kubeconfig and out/node-token
set -euo pipefail
cd "$(dirname "$0")"
source ./jl.conf
mkdir -p out
SSH="ssh -i $SSH_KEY -o StrictHostKeyChecking=accept-new ${SSH_USER}@${SERVER_PUBLIC_IP}"

# Solo mode: the server is also a GPU node (one VM does everything).
EXTRA=""
if echo "$GPU_NODES" | awk '{print $1}' | grep -qx "$SERVER_PUBLIC_IP"; then
  echo ">> Solo mode: ${SERVER_PUBLIC_IP} is both the server and a GPU node"
  EXTRA="--default-runtime nvidia"
fi
echo ">> Installing k3s ${K3S_VERSION} server on ${SERVER_PUBLIC_IP}"
# ExtendedResourceToleration: like GKE, automatically add the nvidia.com/gpu toleration
# to any pod that requests a GPU (we taint GPU nodes in 03-platform.sh).
$SSH "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION='${K3S_VERSION}' sh -s - server \
  --tls-san ${SERVER_PUBLIC_IP} --tls-san ${SERVER_PRIVATE_IP} \
  --node-ip ${SERVER_PRIVATE_IP} \
  --disable traefik \
  --kube-apiserver-arg=enable-admission-plugins=NodeRestriction,ExtendedResourceToleration \
  --node-label workshop.devfest/pool=system ${EXTRA}"

$SSH "cat /var/lib/rancher/k3s/server/node-token" > out/node-token
$SSH "cat /etc/rancher/k3s/k3s.yaml" | sed "s/127.0.0.1/${SERVER_PUBLIC_IP}/" > out/admin.kubeconfig
chmod 600 out/admin.kubeconfig out/node-token

export KUBECONFIG="$PWD/out/admin.kubeconfig"
kubectl get nodes -o wide
echo
echo ">> Done. Use:  export KUBECONFIG=$PWD/out/admin.kubeconfig"
echo ">> Next:      ./scripts/jarvislabs/02-gpu-nodes.sh"
