#!/usr/bin/env bash
# 00-check.sh: is everything ready? Run on your laptop. Changes nothing.
set -uo pipefail
source "$(dirname "$0")/lib.sh"
ok () { printf "  \033[32mOK\033[0m   %s\n" "$*"; }; bad () { printf "  \033[31mFAIL\033[0m %s\n" "$*"; }
echo "== Laptop tools"
for t in ssh scp kubectl helm jq; do command -v $t >/dev/null && ok "$t" || bad "$t missing (brew install $t)"; done
[[ -n "${HF_TOKEN:-}" ]] && ok "HF_TOKEN set" || bad "HF_TOKEN not exported (needed for Gemma)"
[[ "$TS_AUTHKEY" != *CHANGE-ME* ]] && ok "Tailscale key set" || bad "TS_AUTHKEY not set in demo.conf"
echo "== GPU VMs"
for n in $(all_vms); do
  g=$(on "$n" "nvidia-smi --query-gpu=name,memory.total --format=csv,noheader" 2>/dev/null | head -1)
  [[ -n "$g" ]] && ok "$n: $g" || bad "$n ($(vm_ip "$n")): no SSH or no NVIDIA driver"
done
