#!/usr/bin/env bash
# 99-cleanup.sh: tear the cluster down (kubeadm reset on every VM). Then delete the VMs in the Jarvislabs console.
set -uo pipefail
source "$(dirname "$0")/lib.sh"
for n in $(all_vms); do
  on "$n" "kubeadm reset -f >/dev/null 2>&1; rm -rf /etc/cni/net.d \$HOME/.kube; for l in cilium_host cilium_net cilium_vxlan; do ip link delete \$l 2>/dev/null; done; true"
  echo "reset $n"
done
rm -rf "$DEMO_DIR/out"
echo ">> Now: delete the 3 VMs in the Jarvislabs console, and revoke the Hugging Face token."
