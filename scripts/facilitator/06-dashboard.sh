#!/usr/bin/env bash
# 06-dashboard.sh: create the Cloud Monitoring dashboard shown on the projector in Lab 3.
set -euo pipefail
cd "$(dirname "$0")/../.."
source ./workshop.conf
sed "s/gpu-share/${CLUSTER}/g" scripts/facilitator/dashboard.json > /tmp/dashboard.json
gcloud monitoring dashboards create --project="$WORKSHOP_PROJECT" --config-from-file=/tmp/dashboard.json
echo "Open: https://console.cloud.google.com/monitoring/dashboards?project=${WORKSHOP_PROJECT}"
