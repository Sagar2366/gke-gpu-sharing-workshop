#!/usr/bin/env bash
# 07-serve-kubeconfigs.sh: let attendees download their kubeconfig from the server VM.
#
# Copies out/kubeconfigs/ to the server under a random secret path and serves it
# on port 8088 for the duration of the workshop (Ctrl-C or reboot stops it).
# Prints the KUBECONFIG_BASE_URL to put in workshop.conf (then push the repo).
#
# This is workshop-grade, not production: tokens travel over plain HTTP and expire
# after 24h. Delete the server VM (or the tokens' namespaces) right after the event.
set -euo pipefail
cd "$(dirname "$0")"
source ./jl.conf
SECRET="${KC_SECRET:-$(head -c 12 /dev/urandom | base64 | tr -dc a-zA-Z0-9 | head -c 16)}"
SSH="ssh -i $SSH_KEY ${SSH_USER}@${SERVER_PUBLIC_IP}"

$SSH "rm -rf /srv/kc && mkdir -p /srv/kc/${SECRET}"
scp -i "$SSH_KEY" -q out/kubeconfigs/*.yaml "${SSH_USER}@${SERVER_PUBLIC_IP}:/srv/kc/${SECRET}/"
$SSH "pkill -f 'http.server 8088' || true; cd /srv/kc && nohup python3 -m http.server 8088 </dev/null >/var/log/kc.log 2>&1 &"

URL="http://${SERVER_PUBLIC_IP}:8088/${SECRET}"
echo ">> Serving kubeconfigs at: $URL/<table>-<team>.yaml"
echo
echo "Put this line in workshop.conf (inside the jarvislabs block), commit and push:"
echo "  export KUBECONFIG_BASE_URL=\"$URL\""
echo
echo "Test: curl -fsS $URL/$(ls out/kubeconfigs | head -1) | head -3"
