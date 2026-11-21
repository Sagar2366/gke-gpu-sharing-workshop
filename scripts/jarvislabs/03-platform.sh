#!/usr/bin/env bash
# 03-platform.sh: GPU Operator + monitoring in one go (used by up.sh).
#   INITIAL_MODE=exclusive (default) or ts. See 03-gpu-operator.sh.
set -euo pipefail
cd "$(dirname "$0")"
./03-gpu-operator.sh
./03b-monitoring.sh
