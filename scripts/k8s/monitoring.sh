#!/usr/bin/env bash
# monitoring.sh: Prometheus + Grafana with NVIDIA's DCGM GPU dashboard (Grafana on NodePort 30300).
set -euo pipefail
cd "$(dirname "$0")"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update prometheus-community >/dev/null
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack -n monitoring --create-namespace \
  -f monitoring-values.yaml --wait --timeout 15m >/dev/null
helm upgrade gpu-operator nvidia/gpu-operator -n gpu-operator --reuse-values --set dcgmExporter.serviceMonitor.enabled=true >/dev/null
echo ">> Grafana on port 30300 of any node (anonymous read-only)"
