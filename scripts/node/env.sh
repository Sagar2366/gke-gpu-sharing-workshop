# env.sh: settings for the workshop tasks on YOUR GPU VM. Use:  source scripts/node/env.sh
_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$_root/workshop.conf"
export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"
[[ -f "$KUBECONFIG" ]] || export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
export TABLE=me                     # your node is labelled workshop.devfest/table=me
export TEAM="${TEAM:-dosa}"
export IMAGE="$BASE_IMAGE"          # plain vLLM image on your own VM
export WORKSHOP_ROOT="$_root"
if [[ -n "${HF_TOKEN:-}" ]]; then
  export MODEL="${MODEL:-google/gemma-3-1b-it}"
else
  export MODEL="${MODEL:-Qwen/Qwen2.5-1.5B-Instruct}"   # no Hugging Face login needed
fi
case "$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1)" in
  *H200*) export MIG_PARTITION=1g.18gb MIG_CONFIG=all-1g.18gb ;;
  *H100*) export MIG_PARTITION=1g.10gb MIG_CONFIG=all-1g.10gb ;;
  *A100*80*) export MIG_PARTITION=1g.10gb MIG_CONFIG=all-1g.10gb ;;
  *A100*) export MIG_PARTITION=1g.5gb MIG_CONFIG=all-1g.5gb ;;
esac
grep -q "gpu-workshop/env" ~/.bashrc 2>/dev/null || echo "source $_root/scripts/node/env.sh  # gpu-workshop/env" >> ~/.bashrc
echo "KUBECONFIG=$KUBECONFIG  TABLE=$TABLE  MODEL=$MODEL  MIG=${MIG_PARTITION:-n/a}"
