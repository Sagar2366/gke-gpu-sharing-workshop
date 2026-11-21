#!/usr/bin/env bash
# hami-install.sh: install HAMi (CNCF): per-pod GPU memory and compute limits.
# mode.sh hami runs this for you. Nothing changes until a node is labelled gpu=on.
set -euo pipefail
if helm -n kube-system status hami >/dev/null 2>&1; then exit 0; fi
KVER=$(kubectl version -o json | jq -r .serverVersion.gitVersion | sed 's/+.*//')   # HAMi's scheduler must match
echo ">> Installing HAMi (for Kubernetes $KVER, 1-2 minutes)"
helm repo add hami-charts https://project-hami.github.io/HAMi/ >/dev/null 2>&1 || true
helm repo update hami-charts >/dev/null
helm upgrade --install hami hami-charts/hami -n kube-system ${HAMI_VERSION:+--version "$HAMI_VERSION"} \
  --set scheduler.kubeScheduler.imageTag="$KVER" --wait --timeout 10m >/dev/null
