#!/usr/bin/env bash
# 00-doctor.sh: preflight check. Run it the day before AND 30 min before the live build.
# Every line should say OK. It changes nothing.
#
#   ./scripts/jarvislabs/00-doctor.sh
set -uo pipefail
cd "$(dirname "$0")"
[[ -f jl.conf ]] || { echo "FAIL  scripts/jarvislabs/jl.conf missing: cp jl.conf.example jl.conf and fill it in"; exit 1; }
source ./jl.conf
fails=0
ok ()   { printf "  \033[32mOK\033[0m    %s\n" "$*"; }
bad ()  { printf "  \033[31mFAIL\033[0m  %s\n" "$*"; fails=$((fails+1)); }
warn () { printf "  \033[33mWARN\033[0m  %s\n" "$*"; }
SSHO=(-i "$SSH_KEY" -o BatchMode=yes -o ConnectTimeout=8 -o StrictHostKeyChecking=accept-new)

echo "== Your machine"
for t in ssh scp kubectl helm jq curl envsubst; do
  command -v "$t" >/dev/null && ok "$t installed" || bad "$t not installed"
done
[[ -f "$SSH_KEY" ]] && ok "SSH key $SSH_KEY" || bad "SSH key $SSH_KEY not found"
[[ "$KC_SECRET" == "change-me-16chars" ]] && warn "KC_SECRET still the example value (set a real one)" || ok "KC_SECRET set"
[[ -f "$ATTENDEES_CSV" ]] && ok "attendee CSV: $(($(wc -l < "$ATTENDEES_CSV") - 1)) attendees" || bad "attendee CSV $ATTENDEES_CSV not found"
[[ -n "${HF_TOKEN:-}" ]] && ok "HF_TOKEN in environment" || warn "HF_TOKEN not exported (needed by prep-hosts.sh for the Gemma cache)"

echo "== Server VM ${SERVER_PUBLIC_IP}"
if ssh "${SSHO[@]}" "${SSH_USER}@${SERVER_PUBLIC_IP}" true 2>/dev/null; then
  ok "SSH"
  ssh "${SSHO[@]}" "${SSH_USER}@${SERVER_PUBLIC_IP}" "nproc; free -g | awk '/Mem/{print \$2}'" 2>/dev/null | paste -sd' ' \
    | awk '{ if ($1>=4 && $2>=15) print "  \033[32mOK\033[0m    " $1 " vCPU, " $2 " GB RAM"; else print "  \033[33mWARN\033[0m  only " $1 " vCPU, " $2 " GB RAM (8 vCPU / 32 GB recommended)" }'
else
  bad "cannot SSH to server"
fi

echo "== GPU VMs"
echo "$GPU_NODES" | while read -r ip table role; do
  [[ -z "$ip" ]] && continue
  out=$(ssh "${SSHO[@]}" "${SSH_USER}@${ip}" '
    g=$(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null | head -1)
    echo "gpu=${g:-none}"
    command -v docker >/dev/null && echo docker=yes || echo docker=no
    command -v nvidia-ctk >/dev/null && echo toolkit=yes || echo toolkit=no
    [ -f /var/lib/workshop/lab-image.tar ] && echo image=yes || echo image=no
    [ -d /var/lib/workshop/hf/models--google--gemma-3-1b-it ] && echo model=yes || echo model=no
    timeout 4 bash -c "</dev/tcp/'"${SERVER_PRIVATE_IP}"'/22" 2>/dev/null && echo net=yes || echo net=no
  ' 2>/dev/null) || { bad "$ip ($role $table): cannot SSH"; continue; }
  gpu=$(sed -n 's/^gpu=//p' <<<"$out")
  [[ "$gpu" != "none" ]] && ok "$ip ($role $table): $gpu" || bad "$ip ($role $table): no working NVIDIA driver (prep-hosts.sh installs it)"
  for k in docker toolkit image model net; do
    v=$(sed -n "s/^$k=//p" <<<"$out")
    case "$k:$v" in
      docker:no)  bad "$ip: docker missing" ;;
      toolkit:no) warn "$ip: NVIDIA container toolkit missing (prep-hosts.sh)" ;;
      image:no)   warn "$ip: workshop image not prepared (prep-hosts.sh)" ;;
      model:no)   [[ "$role" != "mig" ]] && warn "$ip: Gemma not cached (prep-hosts.sh with HF_TOKEN)" ;;
      net:no)     bad "$ip: can't reach server private IP ${SERVER_PRIVATE_IP} (check private networking)" ;;
    esac
  done
done

echo "== Ports attendees need on ${SERVER_PUBLIC_IP} (only open once the cluster is up)"
for p in 6443 8088 30300 30090; do
  timeout 4 bash -c "</dev/tcp/${SERVER_PUBLIC_IP}/$p" 2>/dev/null && ok "port $p reachable" || warn "port $p not reachable yet (expected before up.sh; must be OK after)"
done

echo
[[ $fails == 0 ]] && echo "All required checks passed." || { echo "$fails check(s) failed."; exit 1; }
