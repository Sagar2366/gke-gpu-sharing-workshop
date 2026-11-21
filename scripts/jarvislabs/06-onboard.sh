#!/usr/bin/env bash
# 06-onboard.sh: per-attendee namespaces and kubeconfigs for Plan B.
#
# Attendees don't have Google IAM on this cluster, so each one gets a ServiceAccount
# token scoped to their namespace, packed into a kubeconfig file.
#
# Usage: ./scripts/jarvislabs/06-onboard.sh ../facilitator/attendees.csv
#   (same CSV as Plan A: email,table,team; email is ignored here)
# Writes: scripts/jarvislabs/out/kubeconfigs/<table>-<team>.yaml (valid 24h)
set -euo pipefail
cd "$(dirname "$0")"
source ./jl.conf
source ../../workshop.conf
export KUBECONFIG="$PWD/out/admin.kubeconfig"
CSV="${1:-$ATTENDEES_CSV}"; [[ -f "$CSV" ]] || { echo "attendee CSV not found: $CSV (set ATTENDEES_CSV in jl.conf)"; exit 1; }
mkdir -p out/kubeconfigs
CA=$(kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')

kubectl apply -f - <<'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata: {name: workshop-node-reader}
rules:
- apiGroups: [""]
  resources: ["nodes", "namespaces"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["daemonsets"]
  verbs: ["get", "list"]
EOF

tail -n +2 "$CSV" | while IFS=, read -r _email table team; do
  [[ -z "$table" ]] && continue
  ns="${table}-${team}"
  kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
  kubectl -n "$ns" create serviceaccount attendee --dry-run=client -o yaml | kubectl apply -f - >/dev/null
  kubectl -n "$ns" create rolebinding attendee-edit --clusterrole=edit --serviceaccount="$ns:attendee" \
    --dry-run=client -o yaml | kubectl apply -f - >/dev/null
  kubectl create clusterrolebinding "node-reader-$ns" --clusterrole=workshop-node-reader \
    --serviceaccount="$ns:attendee" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
  kubectl apply -n "$ns" -f - >/dev/null <<EOF
apiVersion: v1
kind: ResourceQuota
metadata: {name: gpu-quota}
spec:
  hard: {requests.nvidia.com/gpu: "3", pods: "10"}
EOF
  kubectl -n "$ns" create configmap gpu-scripts \
    --from-file=../../workloads/probe.py --from-file=../../workloads/burn.py --from-file=../../workloads/memhog.py \
    --dry-run=client -o yaml | kubectl apply -f - >/dev/null

  token=$(kubectl -n "$ns" create token attendee --duration=24h)
  cat > "out/kubeconfigs/${ns}.yaml" <<EOF
apiVersion: v1
kind: Config
clusters:
- name: planb
  cluster:
    server: https://${SERVER_PUBLIC_IP}:6443
    certificate-authority-data: ${CA}
users:
- name: ${ns}
  user: {token: ${token}}
contexts:
- name: ${ns}
  context: {cluster: planb, user: ${ns}, namespace: ${ns}}
current-context: ${ns}
EOF
  echo "OK  $ns"
done
chmod 600 out/kubeconfigs/*.yaml
echo ">> Next: ./scripts/jarvislabs/07-serve-kubeconfigs.sh"
