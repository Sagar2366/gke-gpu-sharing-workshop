#!/usr/bin/env bash
# join-gpu-node.sh: (instructor, LIVE) add one GPU VM to the cluster over Tailscale.
#
#   ./scripts/cluster/join-gpu-node.sh h200-1
#
# The VM must have been prepared with prep-gpu-vms.sh. Takes ~1 minute.
set -euo pipefail
cd "$(dirname "$0")"
source ./cluster.conf
NAME="${1:?usage: $0 <node-name from GPU_VMS>}"
IP=$(echo "$GPU_VMS" | awk -v n="$NAME" '$2==n {print $1}')
[[ -n "$IP" ]] || { echo "no VM named $NAME in cluster.conf"; exit 1; }
ssh -i "$SSH_KEY" "$SSH_USER@$IP" "sudo TS_AUTHKEY='$TS_AUTHKEY' K3S_URL='https://$(cat out/cp-tailscale-ip):6443' K3S_TOKEN='$(cat out/token)' NODE_TABLE='$NAME' K3S_VERSION='${K3S_VERSION:-}' ~/workshop/scripts/node/join-agent.sh"
export KUBECONFIG="$PWD/out/kubeconfig"
kubectl wait --for=condition=Ready node -l workshop.devfest/table="$NAME" --timeout=180s >/dev/null 2>&1 || true
kubectl get nodes -o wide
