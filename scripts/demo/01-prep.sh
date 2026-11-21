#!/usr/bin/env bash
# 01-prep.sh: the slow, boring part. Run the day before (or 1 hour before). ~10 min.
# On every VM: copy this repo, install the NVIDIA container toolkit, containerd, kubeadm/kubelet,
# and start downloading the workshop image.
set -euo pipefail
source "$(dirname "$0")/lib.sh"
tar -C "$ROOT" --exclude .git --exclude .venv --exclude site --exclude 'scripts/demo/out' -czf /tmp/workshop.tgz .
for n in $(all_vms); do
  ( scp "${SSHO[@]}" -q /tmp/workshop.tgz "$SSH_USER@$(vm_ip "$n"):/tmp/" &&
    on "$n" "rm -rf ~/workshop && mkdir -p ~/workshop && tar -xzf /tmp/workshop.tgz -C ~/workshop &&
             sudo ~/workshop/scripts/node/prep.sh &&
             sudo NODE_IP=$(vm_priv "$n") K8S_MINOR=$K8S_MINOR ~/workshop/scripts/node/kubeadm-prep.sh" \
      > "$DEMO_DIR/out/prep-$n.log" 2>&1 && echo "OK   $n  $(tail -1 "$DEMO_DIR/out/prep-$n.log")" \
      || echo "FAIL $n: see scripts/demo/out/prep-$n.log" ) &
done
wait
