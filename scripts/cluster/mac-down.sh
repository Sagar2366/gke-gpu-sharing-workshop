#!/usr/bin/env bash
# mac-down.sh: remove the control-plane VM from your Mac (delete the Jarvislabs VMs in their console).
set -euo pipefail
cd "$(dirname "$0")"
source ./cluster.conf
multipass delete --purge "$CP_VM" && rm -rf out
echo "Removed $CP_VM. Also remove the machines from your Tailscale admin console if they weren't ephemeral."
