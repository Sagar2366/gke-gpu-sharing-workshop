#!/usr/bin/env bash
# 99-cleanup.sh: tear everything down. Then delete the VMs in the Jarvislabs console.
set -uo pipefail
source "$(dirname "$0")/lib.sh"
for n in $(all_vms); do
  on "$n" "[ -x /usr/local/bin/k3s-agent-uninstall.sh ] && /usr/local/bin/k3s-agent-uninstall.sh; [ -x /usr/local/bin/k3s-uninstall.sh ] && /usr/local/bin/k3s-uninstall.sh; tailscale logout" >/dev/null 2>&1
  echo "cleaned $n"
done
rm -rf "$DEMO_DIR/out"
echo ">> Now: delete the 3 VMs in the Jarvislabs console, revoke the Tailscale key and the HF token."
