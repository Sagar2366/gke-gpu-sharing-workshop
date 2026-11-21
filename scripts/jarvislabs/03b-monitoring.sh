#!/usr/bin/env bash
# 03b-monitoring.sh: Prometheus + Grafana with NVIDIA's DCGM GPU dashboard.
# Grafana: http://<server>:30300 (read-only for attendees), Prometheus: :30090
set -euo pipefail
cd "$(dirname "$0")"
source ./jl.conf
export KUBECONFIG="$PWD/out/admin.kubeconfig"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update prometheus-community >/dev/null
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack -n monitoring --create-namespace \
  -f monitoring-values.yaml --wait --timeout 15m
echo ">> Grafana: http://${SERVER_PUBLIC_IP}:30300   Prometheus: http://${SERVER_PUBLIC_IP}:30090"
