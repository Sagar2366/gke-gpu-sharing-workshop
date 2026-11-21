#!/usr/bin/env bash
# kubeadm-prep.sh: everything a VM needs BEFORE `kubeadm init` / `kubeadm join`. Run ON the VM, as root:
#
#   sudo NODE_IP=<this VM's private IP> ./scripts/node/kubeadm-prep.sh
#
# containerd (with NVIDIA as the default runtime), kubeadm/kubelet/kubectl, the kernel settings
# Kubernetes needs, and pre-pulled images. Run after prep.sh. Safe to re-run.
set -euo pipefail
cd "$(dirname "$0")/../.."
source ./workshop.conf
: "${NODE_IP:?set NODE_IP to the private IP of this VM}"
K8S_MINOR="${K8S_MINOR:-v1.36}"
export DEBIAN_FRONTEND=noninteractive

echo ">> 1/5  kernel settings (no swap, bridge networking, IP forwarding)"
swapoff -a; sed -i '/\sswap\s/ s/^/#/' /etc/fstab
printf "overlay\nbr_netfilter\n" > /etc/modules-load.d/k8s.conf; modprobe overlay; modprobe br_netfilter
cat > /etc/sysctl.d/99-k8s.conf <<SYS
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
SYS
sysctl --system >/dev/null

echo ">> 2/5  containerd, with NVIDIA as the default runtime"
systemctl stop docker docker.socket 2>/dev/null; systemctl disable docker docker.socket 2>/dev/null || true   # Jarvislabs may run Docker
command -v containerd >/dev/null || { apt-get update -y -q && apt-get install -y -q containerd; }
mkdir -p /etc/containerd
[ -s /etc/containerd/config.toml ] || containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
nvidia-ctk runtime configure --runtime=containerd --set-as-default >/dev/null
systemctl restart containerd && systemctl enable containerd >/dev/null 2>&1
printf "runtime-endpoint: unix:///run/containerd/containerd.sock\nimage-endpoint: unix:///run/containerd/containerd.sock\n" > /etc/crictl.yaml

echo ">> 3/5  kubeadm, kubelet, kubectl ($K8S_MINOR)"
if ! command -v kubeadm >/dev/null; then
  apt-get install -y -q apt-transport-https ca-certificates curl gpg
  mkdir -p /etc/apt/keyrings
  curl -fsSL "https://pkgs.k8s.io/core:/stable:/${K8S_MINOR}/deb/Release.key" | gpg --dearmor --yes -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
  echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${K8S_MINOR}/deb/ /" > /etc/apt/sources.list.d/kubernetes.list
  apt-get update -y -q && apt-get install -y -q kubelet kubeadm kubectl && apt-mark hold kubelet kubeadm kubectl >/dev/null
fi
# make the kubelet use the PRIVATE network
echo "KUBELET_EXTRA_ARGS=--node-ip=${NODE_IP}" > /etc/default/kubelet
systemctl restart kubelet 2>/dev/null || true
systemctl enable kubelet >/dev/null 2>&1

echo ">> 4/5  pre-pull Kubernetes' own images"
kubeadm config images pull >/dev/null

echo ">> 5/5  start pulling the ~10 GB workshop image in the background"
REF="$BASE_IMAGE"; [[ "$REF" == */*/* ]] || REF="docker.io/$REF"
nohup ctr -n k8s.io images pull "$REF" >/var/log/workshop-image-pull.log 2>&1 </dev/null &
echo ">> Ready for kubeadm ($(kubeadm version -o short))"
