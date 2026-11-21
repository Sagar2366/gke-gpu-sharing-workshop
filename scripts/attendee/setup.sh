#!/usr/bin/env bash
# setup.sh: attendee setup. Run in Cloud Shell:
#
#   source scripts/attendee/setup.sh t07 dosa
#
# (use the table id on your table card and your team: dosa | idli | vada | chai)
# Use `source`, not `bash`, so the variables stay in your shell.

_ws_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${_ws_root}/workshop.conf"

if [[ $# -ge 2 ]]; then
  export TABLE="$1" TEAM="$2"
elif [[ -f "$HOME/.gpu-workshop-env" ]]; then
  source "$HOME/.gpu-workshop-env"
fi

if [[ -z "${TABLE:-}" || -z "${TEAM:-}" ]]; then
  echo "usage: source scripts/attendee/setup.sh <table> <team>   e.g. t07 dosa"
  return 1 2>/dev/null || exit 1
fi
case "$TEAM" in dosa|idli|vada|chai) ;; *) echo "team must be dosa|idli|vada|chai"; return 1 2>/dev/null || exit 1;; esac

export NS="${TABLE}-${TEAM}"
export WORKSHOP_ROOT="$_ws_root"

# Remember choices for new Cloud Shell tabs.
cat > "$HOME/.gpu-workshop-env" <<EOF
export TABLE="$TABLE" TEAM="$TEAM"
EOF
grep -q "gpu-workshop/attendee-autoload" "$HOME/.bashrc" 2>/dev/null || \
  echo "source ${_ws_root}/scripts/attendee/setup.sh >/dev/null  # gpu-workshop/attendee-autoload" >> "$HOME/.bashrc"

if [[ "$PLATFORM" == "jarvislabs" ]]; then
  # Plan B: download this team's kubeconfig from the backup cluster.
  mkdir -p "$HOME/.kube"
  export KUBECONFIG="$HOME/.kube/gpu-workshop-planb"
  curl -fsS "${KUBECONFIG_BASE_URL}/${NS}.yaml" -o "$KUBECONFIG" \
    || { echo "!! Couldn't download the kubeconfig for $NS. Check table/team spelling, or ask a helper."; return 1 2>/dev/null || exit 1; }
  chmod 600 "$KUBECONFIG"
  echo "export KUBECONFIG=\"$KUBECONFIG\"" >> "$HOME/.gpu-workshop-env"
else
  gcloud container clusters get-credentials "$CLUSTER" --location="$ZONE" --project="$WORKSHOP_PROJECT" >/dev/null 2>&1 \
    || { echo "!! get-credentials failed. Is your Google account on the attendee list? Ask a helper."; return 1 2>/dev/null || exit 1; }
  kubectl config set-context --current --namespace="$NS" >/dev/null
fi

cat <<EOF
=====================================================
  One GPU, Four Teams | DevFest Bengaluru
  table     : $TABLE
  team      : $TEAM
  namespace : $NS
  cluster   : $( [[ "$PLATFORM" == "jarvislabs" ]] && echo "Plan B backup cluster (Jarvislabs)" || echo "$CLUSTER ($ZONE, project $WORKSHOP_PROJECT)" )
=====================================================
EOF
