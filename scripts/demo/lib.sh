# lib.sh for scripts/demo (sourced).
DEMO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$DEMO_DIR/../.." && pwd)"
[[ -f "$DEMO_DIR/demo.conf" ]] || { echo "!! copy scripts/demo/demo.conf.example to scripts/demo/demo.conf and fill it in"; exit 1; }
source "$DEMO_DIR/demo.conf"
source "$ROOT/workshop.conf"
mkdir -p "$DEMO_DIR/out"
export KUBECONFIG="$DEMO_DIR/out/kubeconfig"
SSHO=(-i "$SSH_KEY" -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10)
vm_ip ()   { echo "$VMS" | awk -v n="$1" '$3==n {print $1}'; }   # public IP
vm_priv () { echo "$VMS" | awk -v n="$1" '$3==n {print $2}'; }   # private IP
first_vm () { echo "$VMS" | awk 'NF {print $3; exit}'; }
all_vms () { echo "$VMS" | awk 'NF {print $3}'; }
on () { local n=$1; shift; ssh "${SSHO[@]}" "$SSH_USER@$(vm_ip "$n")" "$@"; }
