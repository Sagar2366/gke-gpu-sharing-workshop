#!/usr/bin/env bash
# 03-join.sh: LIVE. `kubeadm join` one more GPU VM over the private network.   ./scripts/demo/03-join.sh h200-2
set -euo pipefail
source "$(dirname "$0")/lib.sh"
N="${1:?usage: $0 <vm-name>}"
on "$N" "[ -f /etc/kubernetes/kubelet.conf ] || $(cat "$DEMO_DIR/out/join-command") --node-name $N >/var/log/kubeadm-join.log 2>&1 \
  || { tail -20 /var/log/kubeadm-join.log; exit 1; }"
for i in $(seq 1 30); do kubectl get node "$N" >/dev/null 2>&1 && break; sleep 3; done
kubectl label node "$N" workshop.devfest/gpu=true workshop.devfest/table="$N" --overwrite >/dev/null
kubectl -n kube-system rollout status ds/cilium --timeout=300s >/dev/null 2>&1 || true
kubectl wait --for=condition=Ready node/"$N" --timeout=180s >/dev/null 2>&1 || true
kubectl get nodes -o wide
