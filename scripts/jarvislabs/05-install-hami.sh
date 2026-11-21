#!/usr/bin/env bash
# 05-install-hami.sh: install HAMi (CNCF), the GPU sharing layer with ENFORCED memory and
# compute limits. Run once before switching tables to HAMi (04-switch-strategy.sh hami does
# this for you). Nothing changes until a node is labelled gpu=on.
#
#   ./scripts/jarvislabs/05-install-hami.sh
#
# Check the chart values at rehearsal (helm show values hami-charts/hami); key names can change
# between HAMi releases.
set -euo pipefail
cd "$(dirname "$0")"
source ./jl.conf
export KUBECONFIG="$PWD/out/admin.kubeconfig"

if helm -n kube-system status hami >/dev/null 2>&1; then echo ">> HAMi already installed"; exit 0; fi

# HAMi runs a scheduler that must match the cluster's Kubernetes version (k3s: strip "+k3s1").
KVER=$(kubectl version -o json | jq -r .serverVersion.gitVersion | sed 's/+.*//')
echo ">> Installing HAMi (scheduler for Kubernetes $KVER)"
helm repo add hami-charts https://project-hami.github.io/HAMi/ >/dev/null 2>&1 || true
helm repo update hami-charts >/dev/null
helm upgrade --install hami hami-charts/hami -n kube-system \
  ${HAMI_VERSION:+--version "$HAMI_VERSION"} \
  --set scheduler.kubeScheduler.imageTag="$KVER" \
  --wait --timeout 10m
kubectl -n kube-system get pods -l app.kubernetes.io/instance=hami
