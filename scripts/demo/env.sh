# env.sh: run in every new laptop terminal:   source scripts/demo/env.sh
_d="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_d/../../workshop.conf"
export KUBECONFIG="$_d/out/kubeconfig"
[[ -f "$_d/demo.conf" ]] && source "$_d/demo.conf"
export CP_IP="$(echo "${VMS:-}" | awk 'NF{print $1; exit}')"   # public IP of the first VM
export IMAGE="$BASE_IMAGE"
export MODEL="${MODEL:-google/gemma-3-1b-it}"
export MIG_PARTITION="${MIG_PARTITION:-1g.18gb}" MIG_CONFIG="${MIG_CONFIG:-all-1g.18gb}" MIG_MEMHOG_GIB="${MIG_MEMHOG_GIB:-24}"
export TABLE="${TABLE:-h200-1}" TEAM="${TEAM:-dosa}"
echo "KUBECONFIG=$KUBECONFIG  IMAGE=$IMAGE  MODEL=$MODEL"
