#!/usr/bin/env bash
# 07-otel-demo.sh: set up the finale. The OpenTelemetry Astronomy Shop, with its AI
# assistant backed by a live Gemma 4 model on a time-shared L4, plus a noisy
# neighbour you switch on in front of the room.
#
# Prerequisites:
#   - Cluster from 01-create-cluster.sh, plus the demo CPU pool:
#       POOLS="demo" ./scripts/facilitator/01-create-cluster.sh
#   - A "stage" L4 that no attendee table uses: create TABLES+1 time-sharing nodes, then
#       STAGE=1 ./scripts/facilitator/02-label-tables.sh     (first node becomes t00)
#     or label a spare one by hand:
#       kubectl label node <spare-ts-node> workshop.devfest/table=t00 --overwrite
#   - HF_TOKEN from an account that accepted the Gemma 4 licence on Hugging Face
#   - helm (preinstalled in Cloud Shell)
#
# Usage:  HF_TOKEN=hf_... ./scripts/facilitator/07-otel-demo.sh
#   STAGE_TABLE   table label of the stage GPU            (default t00)
#   GEMMA4_IMAGE  vLLM image that supports Gemma 4        (default: GKE tutorial image)
#   CHART_VERSION pin the demo chart (recommended)        (default: latest)
set -euo pipefail
cd "$(dirname "$0")/../.."
source ./workshop.conf
: "${HF_TOKEN:?export HF_TOKEN=hf_... first}"
export STAGE_TABLE="${STAGE_TABLE:-t00}"
export GEMMA4_IMAGE="${GEMMA4_IMAGE:-us-docker.pkg.dev/vertex-ai/vertex-vision-model-garden-dockers/pytorch-vllm-serve:gemma4}"
export IMAGE
NS=otel-demo

if ! kubectl get nodes -l "${TABLE_LABEL}=${STAGE_TABLE},cloud.google.com/gke-gpu-sharing-strategy=time-sharing" -o name | grep -q node; then
  echo "!! No time-sharing node labelled ${TABLE_LABEL}=${STAGE_TABLE}. Label a spare one first (see header)."; exit 1
fi

kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f -
kubectl -n "$NS" create secret generic hf-token --from-literal=token="$HF_TOKEN" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl -n "$NS" create configmap gpu-scripts \
  --from-file=workloads/probe.py --from-file=workloads/burn.py --from-file=workloads/memhog.py \
  --dry-run=client -o yaml | kubectl apply -f -

echo ">> 1/3  Gemma 4 + noisy neighbour (replicas=0) on stage GPU ${STAGE_TABLE}"
envsubst '${STAGE_TABLE} ${GEMMA4_IMAGE} ${IMAGE}' < scripts/facilitator/otel-demo-gemma.yaml | kubectl apply -f -

echo ">> 2/3  OpenTelemetry Astronomy Shop (Helm)"
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts >/dev/null 2>&1 || true
helm repo update open-telemetry >/dev/null
helm upgrade --install otel-demo open-telemetry/opentelemetry-demo -n "$NS" \
  ${CHART_VERSION:+--version "$CHART_VERSION"} \
  -f scripts/facilitator/otel-demo-values.yaml

echo ">> 3/3  Waiting (Gemma 4 downloads several GB on first start)"
kubectl -n "$NS" rollout status deploy/gemma4 --timeout=30m
kubectl -n "$NS" wait --for=condition=Available deploy --all --timeout=15m || true
kubectl -n "$NS" get pods

cat <<EOF

Ready. On your laptop's Cloud Shell:
  kubectl -n $NS port-forward svc/frontend-proxy 8080:8080
Then Web Preview → port 8080:
  /            the shop
  /chatbot/    the AI shopping assistant (live Gemma 4)
  /jaeger/ui/  traces
  /grafana/    dashboards
  /loadgen/    Locust load generator

Noisy neighbour ON :  kubectl -n $NS scale deploy/noisy-neighbour --replicas=1
Noisy neighbour OFF:  kubectl -n $NS scale deploy/noisy-neighbour --replicas=0
Tear down          :  helm -n $NS uninstall otel-demo && kubectl delete ns $NS
EOF
