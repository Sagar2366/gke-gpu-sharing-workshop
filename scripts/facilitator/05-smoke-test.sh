#!/usr/bin/env bash
# 05-smoke-test.sh: run probe.py once on each kind of pool. Do this at rehearsal
# AND on the morning of the event. Every line should print a device name.
set -euo pipefail
cd "$(dirname "$0")/../.."
source ./workshop.conf
NS=workshop-smoke

kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f -
kubectl create configmap gpu-scripts -n "$NS" \
  --from-file=workloads/probe.py --from-file=workloads/burn.py --from-file=workloads/memhog.py \
  --dry-run=client -o yaml | kubectl apply -f -

run_probe () {  # name, hostIPC, nodeSelector-yaml
  kubectl -n "$NS" delete pod "$1" --ignore-not-found --wait=true >/dev/null
  kubectl apply -n "$NS" -f - <<EOF
apiVersion: v1
kind: Pod
metadata: {name: $1}
spec:
  restartPolicy: Never
  hostIPC: $2
  nodeSelector:
$3
  containers:
  - name: probe
    image: ${IMAGE}
    command: ["python3", "/scripts/probe.py"]
    env: [{name: LD_LIBRARY_PATH, value: /usr/local/nvidia/lib64}]
    resources: {limits: {nvidia.com/gpu: 1}}
    volumeMounts: [{name: scripts, mountPath: /scripts}]
  volumes: [{name: scripts, configMap: {name: gpu-scripts}}]
EOF
}

run_probe smoke-ts false "    cloud.google.com/gke-gpu-sharing-strategy: time-sharing"
run_probe smoke-mps true "    cloud.google.com/gke-gpu-sharing-strategy: mps"
run_probe smoke-mig false "    cloud.google.com/gke-gpu-partition-size: ${MIG_PARTITION}"

for p in smoke-ts smoke-mps smoke-mig; do
  kubectl -n "$NS" wait --for=jsonpath='{.status.phase}'=Succeeded pod/$p --timeout=10m || true
  echo "===== $p"; kubectl -n "$NS" logs $p || true
done

echo
echo "Clean up with: kubectl delete namespace $NS"
