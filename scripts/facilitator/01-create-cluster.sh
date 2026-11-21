#!/usr/bin/env bash
# 01-create-cluster.sh: create the shared GKE Standard cluster and the GPU node pools.
#
# Workshop day (defaults):
#   TABLES=12 MIG_NODES=7 ./scripts/facilitator/01-create-cluster.sh
#
# At home, in your own project, one cheap spot L4 at a time:
#   TABLES=1 POOLS="ts" SPOT=1 ./scripts/facilitator/01-create-cluster.sh
#   (later)  POOLS="mps" ...   or   POOLS="mig" MIG_NODES=1 ...
#
# Env vars:
#   TABLES     tables of 4 attendees = L4 nodes per L4 pool        (default 12)
#   MIG_NODES  A100 40GB nodes; each gives 7 x 1g.5gb slices        (default 7)
#   POOLS      which pools to create: any of "ts mps mig demo"      (default "ts mps mig")
#              "demo" = CPU pool for the OpenTelemetry Astronomy Shop finale (07-otel-demo.sh).
#              For the finale also add ONE extra time-sharing L4 (TABLES=<tables>+1) as the stage GPU.
#   SPOT=1     use Spot VMs (cheap, can be preempted; fine at home, risky on stage)
set -euo pipefail
cd "$(dirname "$0")/../.."
source ./workshop.conf

TABLES="${TABLES:-12}"
MIG_NODES="${MIG_NODES:-7}"
POOLS="${POOLS:-ts mps mig}"
DEMO_MACHINE="${DEMO_MACHINE:-e2-standard-8}"
L4_MACHINE="${L4_MACHINE:-g2-standard-8}"
MIG_MACHINE="${MIG_MACHINE:-a2-highgpu-1g}"
DISK_GB="${DISK_GB:-200}"   # the vLLM image is large; leave room for it
SPOT_FLAG=""; [[ "${SPOT:-0}" == "1" ]] && SPOT_FLAG="--spot"

gcloud config set project "$WORKSHOP_PROJECT"
gcloud services enable container.googleapis.com monitoring.googleapis.com logging.googleapis.com

if ! gcloud container clusters describe "$CLUSTER" --location="$ZONE" >/dev/null 2>&1; then
  echo ">> Creating cluster $CLUSTER in $ZONE (small CPU pool for system pods)"
  gcloud container clusters create "$CLUSTER" \
    --location="$ZONE" \
    --release-channel=regular \
    --machine-type=e2-standard-4 \
    --num-nodes="$([[ $TABLES -gt 2 ]] && echo 2 || echo 1)" \
    --workload-pool="${WORKSHOP_PROJECT}.svc.id.goog" \
    --enable-image-streaming \
    --monitoring=SYSTEM
else
  echo ">> Cluster $CLUSTER already exists; only adding node pools"
fi

create_pool () {  # name, machine, accelerator-spec, nodes
  echo ">> Creating node pool $1 ($4 x $2) ${SPOT_FLAG}"
  # shellcheck disable=SC2086
  gcloud container node-pools create "$1" \
    --cluster="$CLUSTER" --location="$ZONE" \
    --machine-type="$2" \
    --accelerator="$3" \
    --num-nodes="$4" \
    --disk-size="$DISK_GB" \
    --node-labels="workshop.devfest/pool=$1" \
    --no-enable-autoupgrade \
    $SPOT_FLAG \
    --async
}

for p in $POOLS; do
  case "$p" in
    ts)  create_pool "$TS_POOL"  "$L4_MACHINE" \
           "type=nvidia-l4,count=1,gpu-sharing-strategy=time-sharing,max-shared-clients-per-gpu=${CLIENTS},gpu-driver-version=latest" \
           "$TABLES" ;;
    mps) create_pool "$MPS_POOL" "$L4_MACHINE" \
           "type=nvidia-l4,count=1,gpu-sharing-strategy=mps,max-shared-clients-per-gpu=${CLIENTS},gpu-driver-version=latest" \
           "$TABLES" ;;
    mig) create_pool "$MIG_POOL" "$MIG_MACHINE" \
           "type=nvidia-tesla-a100,count=1,gpu-partition-size=${MIG_PARTITION},gpu-driver-version=latest" \
           "$MIG_NODES" ;;
    demo)
         echo ">> Creating node pool demo-cpu (2 x $DEMO_MACHINE) for the Astronomy Shop"
         gcloud container node-pools create demo-cpu \
           --cluster="$CLUSTER" --location="$ZONE" \
           --machine-type="$DEMO_MACHINE" --num-nodes=2 \
           --node-labels="workshop.devfest/pool=demo-cpu" --async ;;
    *)   echo "unknown pool '$p' (use ts, mps, mig, demo)"; exit 1 ;;
  esac
done

echo ">> Node pools are being created asynchronously. Watch with:"
echo "   gcloud container operations list --location=$ZONE --filter='status!=DONE'"
echo ">> When done:"
echo "   gcloud container clusters get-credentials $CLUSTER --location=$ZONE"
echo "   ./scripts/facilitator/02-label-tables.sh"
