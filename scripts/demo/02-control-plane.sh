#!/usr/bin/env bash
# 02-control-plane.sh: LIVE. `kubeadm init` on the first VM, a pod network (Cilium), and kubectl on your laptop.
set -euo pipefail
source "$(dirname "$0")/lib.sh"
CP=$(first_vm); PUB=$(vm_ip "$CP"); PRIV=$(vm_priv "$CP")
echo ">> kubeadm init on $CP ($PRIV)"
on "$CP" "[ -f /etc/kubernetes/admin.conf ] || kubeadm init --node-name $CP --apiserver-advertise-address $PRIV \
  --pod-network-cidr $POD_CIDR --apiserver-cert-extra-sans $PUB,127.0.0.1 >/var/log/kubeadm-init.log 2>&1 \
  || { tail -20 /var/log/kubeadm-init.log; exit 1; }"
on "$CP" "kubeadm token create --print-join-command" > "$DEMO_DIR/out/join-command"
HOST=$PUB; [[ "$API_VIA" == "tunnel" ]] && HOST=127.0.0.1
on "$CP" "cat /etc/kubernetes/admin.conf" | sed -E "s#server: https://[^:]+:6443#server: https://$HOST:6443#" > "$KUBECONFIG"
chmod 600 "$KUBECONFIG"
for i in $(seq 1 30); do kubectl get nodes >/dev/null 2>&1 && break; sleep 2; done
kubectl get nodes >/dev/null || { echo "!! kubectl can't reach https://$HOST:6443 (try API_VIA=tunnel + ./scripts/demo/tunnel.sh)"; exit 1; }

echo ">> pod network: Cilium (pod IPs from each node's slice of $POD_CIDR)"
helm repo add cilium https://helm.cilium.io/ >/dev/null 2>&1 || true; helm repo update cilium >/dev/null
helm upgrade --install cilium cilium/cilium -n kube-system ${CILIUM_VERSION:+--version $CILIUM_VERSION} \
  --set routingMode=tunnel --set tunnelProtocol=vxlan --set ipam.mode=kubernetes >/dev/null
kubectl -n kube-system rollout status ds/cilium --timeout=300s >/dev/null && echo "   Cilium OK"

echo ">> let workloads run on the control-plane VM too (it has a GPU)"
kubectl taint nodes "$CP" node-role.kubernetes.io/control-plane:NoSchedule- >/dev/null 2>&1 || true
kubectl label node "$CP" workshop.devfest/gpu=true workshop.devfest/table="$CP" --overwrite >/dev/null

kubectl create configmap gpu-scripts --from-file="$ROOT/workloads/probe.py" --from-file="$ROOT/workloads/burn.py" \
  --from-file="$ROOT/workloads/memhog.py" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl create secret generic hf-token --from-literal=token="${HF_TOKEN:-none}" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl wait --for=condition=Ready node/"$CP" --timeout=180s >/dev/null 2>&1 || true
kubectl get nodes -o wide
