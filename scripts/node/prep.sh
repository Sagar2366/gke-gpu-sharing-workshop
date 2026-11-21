#!/usr/bin/env bash
# prep.sh: get a fresh GPU VM ready for Kubernetes. Run ON the VM, as root:
#
#   sudo ./scripts/node/prep.sh
#
# Checks the NVIDIA driver, installs the NVIDIA Container Toolkit (so containers can use the GPU),
# plus helm and jq. Safe to re-run. Takes 1-3 minutes.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
[[ $EUID -eq 0 ]] || { echo "run as root: sudo $0"; exit 1; }

echo ">> 1/3  NVIDIA driver"
if nvidia-smi -L 2>/dev/null; then
  echo "   driver OK"
else
  echo "   no working driver. Installing one (then you must reboot and run this again)..."
  apt-get update -y -q && apt-get install -y -q ubuntu-drivers-common
  ubuntu-drivers install --gpgpu
  echo "!! Driver installed. Run: reboot   then log in again and re-run: sudo $0"; exit 42
fi

echo ">> 2/3  NVIDIA Container Toolkit"
if ! command -v nvidia-ctk >/dev/null; then
  curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor --yes -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
  curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
    | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#' \
    > /etc/apt/sources.list.d/nvidia-container-toolkit.list
  apt-get update -y -q && apt-get install -y -q nvidia-container-toolkit
fi
nvidia-ctk --version | head -1

echo ">> 3/3  helm, jq, curl"
command -v jq >/dev/null || apt-get install -y -q jq curl
command -v helm >/dev/null || curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash >/dev/null
helm version --short

echo ">> Ready. Next: ./scripts/node/k3s-single.sh   (or, on the instructor's GPU nodes: join-agent.sh)"
