#!/usr/bin/env bash
# gemma.sh: one team's Gemma chat server (vLLM) on the node in $TABLE.
#
#   TEAM=dosa ./scripts/k8s/gemma.sh                 # vLLM's default: reserve 90% of the GPU's memory
#   GPU_UTIL=0.2 TEAM=dosa ./scripts/k8s/gemma.sh    # reserve only 20%
#
# Creates Deployment + Service "gemma-<team>" (port 8000, OpenAI-compatible API).
set -euo pipefail
: "${IMAGE:?source scripts/demo/env.sh first}" "${TABLE:?export TABLE=<node>}" "${TEAM:?export TEAM=<team>}"
MODEL="${MODEL:-google/gemma-3-1b-it}"
UTIL_ARG=""; [[ -n "${GPU_UTIL:-}" ]] && UTIL_ARG="- --gpu-memory-utilization=${GPU_UTIL}"
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata: {name: gemma-$TEAM}
spec:
  replicas: 1
  strategy: {type: Recreate}
  selector: {matchLabels: {app: gemma-$TEAM}}
  template:
    metadata: {labels: {app: gemma-$TEAM}}
    spec:
      nodeSelector: {workshop.devfest/table: $TABLE}
      containers:
      - name: vllm
        image: $IMAGE
        command: ["python3", "-m", "vllm.entrypoints.openai.api_server"]
        args:
        - --model=$MODEL
        - --max-model-len=4096
        - --enforce-eager
        - --port=8000
        $UTIL_ARG
        env:
        - {name: HF_HOME, value: /models}
        - name: HF_TOKEN
          valueFrom: {secretKeyRef: {name: hf-token, key: token}}
        ports: [{containerPort: 8000}]
        readinessProbe: {httpGet: {path: /health, port: 8000}, periodSeconds: 5, failureThreshold: 120}
        resources:
          requests: {cpu: "2", memory: 8Gi}
          limits: {memory: 16Gi, nvidia.com/gpu: 1}
        volumeMounts: [{name: models, mountPath: /models}]
      volumes:
      - name: models
        hostPath: {path: /var/lib/workshop/hf, type: DirectoryOrCreate}
---
apiVersion: v1
kind: Service
metadata: {name: gemma-$TEAM}
spec:
  selector: {app: gemma-$TEAM}
  ports: [{port: 8000, targetPort: 8000}]
EOF
