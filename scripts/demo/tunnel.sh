#!/usr/bin/env bash
# tunnel.sh: if port 6443 isn't reachable from your laptop, forward it over SSH (use with API_VIA=tunnel).
# Runs in the background; stop it with:  pkill -f "6443:"
set -euo pipefail
source "$(dirname "$0")/lib.sh"
CP=$(first_vm)
ssh "${SSHO[@]}" -fN -L "6443:$(vm_priv "$CP"):6443" "$SSH_USER@$(vm_ip "$CP")"
echo ">> localhost:6443 now reaches the control plane on $CP"
