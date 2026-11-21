#!/usr/bin/env bash
# 00-check.sh: is everything ready? Run on your laptop. Changes nothing.
set -uo pipefail
source "$(dirname "$0")/lib.sh"
ok () { printf "  \033[32mOK\033[0m   %s\n" "$*"; }; bad () { printf "  \033[31mFAIL\033[0m %s\n" "$*"; }
echo "== Laptop tools"
for t in ssh scp kubectl helm jq; do command -v $t >/dev/null && ok "$t" || bad "$t missing (brew install $t)"; done
[[ -n "${HF_TOKEN:-}" ]] && ok "HF_TOKEN set" || bad "HF_TOKEN not exported (needed for Gemma)"
CP=$(first_vm); CPPRIV=$(vm_priv "$CP")
echo "== GPU VMs"
for n in $(all_vms); do
  g=$(on "$n" "nvidia-smi --query-gpu=name,memory.total --format=csv,noheader" 2>/dev/null | head -1)
  [[ -n "$g" ]] && ok "$n: $g" || bad "$n ($(vm_ip "$n")): no SSH or no NVIDIA driver"
  on "$n" "ip -4 addr | grep -q ' $(vm_priv "$n")/'" 2>/dev/null && ok "$n has private IP $(vm_priv "$n")" || bad "$n: private IP $(vm_priv "$n") not found on the VM"
  on "$n" "timeout 3 bash -c '</dev/tcp/$CPPRIV/22'" 2>/dev/null && ok "$n reaches $CP on the private network" || bad "$n can't reach $CPPRIV (same VPC?)"
done
