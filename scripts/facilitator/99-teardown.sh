#!/usr/bin/env bash
# 99-teardown.sh: stop the meter. Run as soon as the workshop ends.
#
#   ./scripts/facilitator/99-teardown.sh attendees.csv   # also removes IAM bindings
set -euo pipefail
cd "$(dirname "$0")/../.."
source ./workshop.conf
CSV="${1:-}"

echo ">> Deleting cluster $CLUSTER (this deletes every node pool and GPU)"
gcloud container clusters delete "$CLUSTER" --location="$ZONE" --quiet

if [[ -n "$CSV" ]]; then
  tail -n +2 "$CSV" | while IFS=, read -r email _ _; do
    [[ -z "$email" ]] && continue
    for role in roles/container.clusterViewer roles/monitoring.viewer; do
      gcloud projects remove-iam-policy-binding "$WORKSHOP_PROJECT" \
        --member="user:${email}" --role="$role" --condition=None >/dev/null 2>&1 || true
    done
    echo "removed IAM for $email"
  done
fi
[[ -n "${GROUP:-}" ]] && for role in roles/container.clusterViewer roles/monitoring.viewer; do
  gcloud projects remove-iam-policy-binding "$WORKSHOP_PROJECT" --member="group:${GROUP}" --role="$role" --condition=None >/dev/null 2>&1 || true
done

echo ">> Done. Also: revoke the Hugging Face token you used in 04-prepull-and-cache.sh."
