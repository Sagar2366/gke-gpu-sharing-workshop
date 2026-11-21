#!/usr/bin/env bash
# 04-prepull-and-cache.sh: run once, ~30-60 min before doors open.
#
# 1. Pulls $IMAGE onto every GPU node, so no attendee waits on a ~10 GB pull.
# 2. Downloads $MODEL into a hostPath cache on every GPU node, so Lab 6 starts
#    in seconds, does not hit Hugging Face 50 times, and attendees never need a
#    Hugging Face token.
#
# Needs: HF_TOKEN in your environment, from an account that has accepted the
# Gemma licence on huggingface.co. Use a read-only token and revoke it afterwards.
set -euo pipefail
cd "$(dirname "$0")/../.."
source ./workshop.conf
: "${HF_TOKEN:?export HF_TOKEN=hf_... first}"

kubectl create namespace workshop-system --dry-run=client -o yaml | kubectl apply -f -
kubectl -n workshop-system create secret generic hf-token \
  --from-literal=token="$HF_TOKEN" --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: prepull-and-cache
  namespace: workshop-system
spec:
  selector:
    matchLabels: {app: prepull-and-cache}
  template:
    metadata:
      labels: {app: prepull-and-cache}
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - {key: cloud.google.com/gke-accelerator, operator: Exists}
      tolerations:
      - {key: nvidia.com/gpu, operator: Exists, effect: NoSchedule}
      initContainers:
      - name: cache-model
        image: ${IMAGE}
        command: ["python3", "-c"]
        args:
        - |
          from huggingface_hub import snapshot_download
          p = snapshot_download("${MODEL}", cache_dir="/models")
          print("cached", p)
        env:
        - name: HF_TOKEN
          valueFrom: {secretKeyRef: {name: hf-token, key: token}}
        volumeMounts:
        - {name: models, mountPath: /models}
      containers:
      - name: pause
        image: registry.k8s.io/pause:3.9
        resources:
          requests: {cpu: 10m, memory: 16Mi}
      volumes:
      - name: models
        hostPath: {path: ${MODEL_CACHE_HOSTPATH}, type: DirectoryOrCreate}
EOF

echo ">> Waiting for every GPU node to finish (image pull + model download)..."
kubectl -n workshop-system rollout status ds/prepull-and-cache --timeout=45m
kubectl -n workshop-system get pods -o wide
