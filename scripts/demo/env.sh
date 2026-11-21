# env.sh: run in every new laptop terminal:   source scripts/demo/env.sh
_d="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_d/../../workshop.conf"
export KUBECONFIG="$_d/out/kubeconfig"
[[ -f "$_d/demo.conf" ]] && source "$_d/demo.conf"
_vm () { echo "${VMS:-}" | awk -v r="$1" -v c="$2" 'NF{i++} NF && i==r {print $c}'; }
export H1=$(_vm 1 1) H2=$(_vm 2 1) H3=$(_vm 3 1)   # public IPs (SSH, Grafana)
export P1=$(_vm 1 2) P2=$(_vm 2 2) P3=$(_vm 3 2)   # private IPs (inside the VPC)
export CP_IP="$H1" API_HOST="$H1"
[[ "${API_VIA:-public}" == "tunnel" ]] && API_HOST=127.0.0.1   # kubectl via ./scripts/demo/tunnel.sh
mkdir -p "$_d/out"
export IMAGE="$BASE_IMAGE"
export MODEL="${MODEL:-google/gemma-3-1b-it}"
export MIG_PARTITION="${MIG_PARTITION:-1g.18gb}" MIG_CONFIG="${MIG_CONFIG:-all-1g.18gb}" MIG_MEMHOG_GIB="${MIG_MEMHOG_GIB:-24}"
export TABLE="${TABLE:-h200-1}" TEAM="${TEAM:-dosa}"
echo "KUBECONFIG=$KUBECONFIG  H1=$H1 H2=$H2 H3=$H3  P1=$P1 P2=$P2 P3=$P3"
