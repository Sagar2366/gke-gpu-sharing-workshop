#!/usr/bin/env bash
# prep-hosts.sh: everything SLOW, done BEFORE the session (the day before, or T-2h).
# After this, the live build (up.sh) only installs Kubernetes and takes ~15 minutes.
#
# On every GPU VM, in parallel:
#   1. NVIDIA driver (installs with ubuntu-drivers if missing; then you reboot and re-run)
#   2. NVIDIA Container Toolkit
#   3. Workshop image = lab image + nvidia-smi path shim, saved to /var/lib/workshop/lab-image.tar
#   4. Gemma 3 1B downloaded into /var/lib/workshop/hf  (needs HF_TOKEN; skipped on the MIG VM)
#
# Safe to re-run: finished steps are skipped.
#   export HF_TOKEN=hf_...
#   ./scripts/jarvislabs/prep-hosts.sh
set -euo pipefail
cd "$(dirname "$0")"
source ./jl.conf
source ../../workshop.conf
mkdir -p out/logs
: "${HF_TOKEN:=}"

prep () {  # ip role
  local ip=$1 role=$2
  ssh -i "$SSH_KEY" -o StrictHostKeyChecking=accept-new "${SSH_USER}@${ip}" bash -s <<EOF
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
mkdir -p /var/lib/workshop/hf

if ! nvidia-smi >/dev/null 2>&1; then
  apt-get update -y && apt-get install -y ubuntu-drivers-common
  ubuntu-drivers install --gpgpu
  echo "driver installed: REBOOT this VM and re-run prep-hosts.sh"; exit 42
fi
nvidia-smi -L

if ! command -v nvidia-ctk >/dev/null; then
  curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor --yes -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
  curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
    | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#' \
    > /etc/apt/sources.list.d/nvidia-container-toolkit.list
  apt-get update -y && apt-get install -y nvidia-container-toolkit
fi
command -v docker >/dev/null || { apt-get update -y && apt-get install -y docker.io; }
nvidia-ctk runtime configure --runtime=docker >/dev/null && systemctl restart docker

if [ ! -f /var/lib/workshop/lab-image.tar ]; then
  mkdir -p /tmp/ws-image && cd /tmp/ws-image
  cat > Dockerfile <<'DOCKER'
ARG BASE
FROM \${BASE}
RUN mkdir -p /usr/local/nvidia/bin /usr/local/nvidia/lib64 && ln -sf /usr/bin/nvidia-smi /usr/local/nvidia/bin/nvidia-smi
DOCKER
  docker build -q --build-arg BASE='${BASE_IMAGE}' -t workshop/lab-image:planb .
  docker save workshop/lab-image:planb -o /var/lib/workshop/lab-image.tar
fi
echo "image: \$(du -h /var/lib/workshop/lab-image.tar | cut -f1)"

if [ "${role}" != "mig" ] && [ -n "${HF_TOKEN}" ] && [ ! -d /var/lib/workshop/hf/models--${MODEL//\//--} ]; then
  docker run --rm --gpus all -e HF_TOKEN='${HF_TOKEN}' -v /var/lib/workshop/hf:/models workshop/lab-image:planb \
    python3 -c "from huggingface_hub import snapshot_download; print(snapshot_download('${MODEL}', cache_dir='/models'))"
fi
ls /var/lib/workshop/hf
echo PREP-DONE
EOF
}

start=$(date +%s)
echo "$GPU_NODES" | while read -r ip table role; do
  [[ -z "$ip" ]] && continue
  ( if prep "$ip" "$role" > "out/logs/prep-${ip}.log" 2>&1; then echo "OK    $ip ($role $table)";
    else rc=$?; [[ $rc == 42 ]] && echo "REBOOT $ip: driver installed, reboot it and re-run" || echo "FAIL  $ip: see out/logs/prep-${ip}.log"; fi ) &
done
wait
echo "prep-hosts finished in $(( ($(date +%s) - start) / 60 )) min. Next: ./scripts/jarvislabs/00-doctor.sh"
