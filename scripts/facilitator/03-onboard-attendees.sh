#!/usr/bin/env bash
# 03-onboard-attendees.sh: give each attendee (a Google account) access to
# their own namespace on the shared cluster.
#
# Usage:  ./scripts/facilitator/03-onboard-attendees.sh attendees.csv
#   CSV columns: email,table,team   (team is one of dosa|idli|vada|chai)
#
# Per attendee this creates:
#   IAM   roles/container.clusterViewer  -> lets `get-credentials` work
#   IAM   roles/monitoring.viewer        -> Metrics Explorer in Lab 3
#   ns    <table>-<team>, e.g. t07-dosa
#   RBAC  "edit" in that namespace + read-only access to nodes
#   quota max 3 nvidia.com/gpu per namespace (the Lab 2 gotcha needs 2)
#   cm    gpu-scripts (probe.py, burn.py, memhog.py)
#
# Tip: with >40 attendees, grant the two IAM roles to a Google Group once
# (GROUP=devfest-gpu@googlegroups.com) instead of per user: much faster.
set -euo pipefail
cd "$(dirname "$0")/../.."
source ./workshop.conf
CSV="${1:?usage: $0 attendees.csv}"

if [[ -n "${GROUP:-}" ]]; then
  for role in roles/container.clusterViewer roles/monitoring.viewer; do
    gcloud projects add-iam-policy-binding "$WORKSHOP_PROJECT" \
      --member="group:${GROUP}" --role="$role" --condition=None >/dev/null
  done
  echo "IAM granted to group $GROUP"
fi

# Cluster-wide: attendees may read nodes (Lab 1 inspects them).
kubectl apply -f - <<'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: workshop-node-reader
rules:
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["namespaces"]
  verbs: ["get", "list"]
EOF

tail -n +2 "$CSV" | while IFS=, read -r email table team; do
  [[ -z "$email" ]] && continue
  ns="${table}-${team}"
  echo ">> $email -> $ns"

  if [[ -z "${GROUP:-}" ]]; then
    for role in roles/container.clusterViewer roles/monitoring.viewer; do
      gcloud projects add-iam-policy-binding "$WORKSHOP_PROJECT" \
        --member="user:${email}" --role="$role" --condition=None >/dev/null
    done
  fi

  kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f -
  kubectl label namespace "$ns" workshop.devfest/attendee=true "${TABLE_LABEL}=${table}" --overwrite

  kubectl apply -n "$ns" -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: attendee-edit
subjects:
- kind: User
  name: ${email}
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: edit
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: gpu-quota
spec:
  hard:
    requests.nvidia.com/gpu: "3"
    pods: "10"
EOF

  kubectl create configmap gpu-scripts -n "$ns" \
    --from-file=workloads/probe.py --from-file=workloads/burn.py --from-file=workloads/memhog.py \
    --dry-run=client -o yaml | kubectl apply -f -

  kubectl create clusterrolebinding "node-reader-${ns}" \
    --clusterrole=workshop-node-reader --user="${email}" \
    --dry-run=client -o yaml | kubectl apply -f - >/dev/null
done

echo
echo "Done. Namespaces:"
kubectl get ns -l workshop.devfest/attendee=true
