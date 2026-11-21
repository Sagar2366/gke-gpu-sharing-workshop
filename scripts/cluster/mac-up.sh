#!/usr/bin/env bash
# mac-up.sh: (instructor, on your Mac) start the control plane in a Multipass VM and get kubectl working.
#
#   brew install --cask multipass && brew install kubectl helm jq
#   cp scripts/cluster/cluster.conf.example scripts/cluster/cluster.conf   # fill in TS_AUTHKEY etc.
#   ./scripts/cluster/mac-up.sh
#
# Writes scripts/cluster/out/kubeconfig and out/token. Then: export KUBECONFIG=$PWD/scripts/cluster/out/kubeconfig
set -euo pipefail
cd "$(dirname "$0")"
source ./cluster.conf
mkdir -p out
multipass info "$CP_VM" >/dev/null 2>&1 || multipass launch 24.04 --name "$CP_VM" --cpus "$CP_CPUS" --memory "$CP_MEM" --disk 30G
multipass transfer control-plane.sh "$CP_VM":/tmp/control-plane.sh
OUT=$(multipass exec "$CP_VM" -- sudo env TS_AUTHKEY="$TS_AUTHKEY" K3S_VERSION="${K3S_VERSION:-}" bash /tmp/control-plane.sh)
echo "$OUT" | tail -2
TSIP=$(sed -n 's/^TSIP=//p' <<<"$OUT"); LANIP=$(sed -n 's/^LANIP=//p' <<<"$OUT")
multipass exec "$CP_VM" -- sudo cat /var/lib/rancher/k3s/server/node-token > out/token
# kubectl from the Mac talks to the VM directly (no Tailscale needed on the Mac)
multipass exec "$CP_VM" -- sudo cat /etc/rancher/k3s/k3s.yaml | sed "s/127.0.0.1/$LANIP/" > out/kubeconfig
echo "$TSIP" > out/cp-tailscale-ip
chmod 600 out/*
export KUBECONFIG="$PWD/out/kubeconfig"
kubectl get nodes -o wide
echo ">> Control plane up. Tailscale IP $TSIP.  export KUBECONFIG=$PWD/out/kubeconfig"
echo ">> Add a GPU node live:  ./scripts/cluster/join-gpu-node.sh h200-1"
