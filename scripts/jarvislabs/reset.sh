#!/usr/bin/env bash
# reset.sh: wipe Kubernetes off every VM (keeps driver, toolkit, image tarball and Gemma cache),
# so you can rehearse the live build again with up.sh. Takes ~1 min.
#
#   ./scripts/jarvislabs/reset.sh        # asks for confirmation
#   YES=1 ./scripts/jarvislabs/reset.sh
set -euo pipefail
cd "$(dirname "$0")"
source ./jl.conf
if [[ "${YES:-0}" != "1" ]]; then
  read -r -p "This deletes the k3s cluster on ALL VMs (prep is kept). Type 'reset' to continue: " a
  [[ "$a" == "reset" ]] || exit 1
fi
SSHO=(-i "$SSH_KEY" -o StrictHostKeyChecking=accept-new)
echo "$GPU_NODES" | while read -r ip _ _; do
  [[ -z "$ip" ]] && continue
  ssh "${SSHO[@]}" "${SSH_USER}@${ip}" '[ -x /usr/local/bin/k3s-agent-uninstall.sh ] && /usr/local/bin/k3s-agent-uninstall.sh >/dev/null 2>&1; echo "reset $(hostname)"' &
done
wait
ssh "${SSHO[@]}" "${SSH_USER}@${SERVER_PUBLIC_IP}" 'pkill -f "http.server 8088" || true; [ -x /usr/local/bin/k3s-uninstall.sh ] && /usr/local/bin/k3s-uninstall.sh >/dev/null 2>&1; echo "reset server"'
rm -rf out/admin.kubeconfig out/node-token out/kubeconfigs
echo "Done. Rebuild with: ./scripts/jarvislabs/up.sh"
