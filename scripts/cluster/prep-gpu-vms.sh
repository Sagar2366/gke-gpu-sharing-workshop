#!/usr/bin/env bash
# prep-gpu-vms.sh: (instructor, the day before) copy the repo to every GPU VM and run node/prep.sh there.
set -euo pipefail
cd "$(dirname "$0")"
source ./cluster.conf
ROOT=$(cd ../.. && pwd); mkdir -p out
tar -C "$ROOT" --exclude .git --exclude .venv --exclude site -czf /tmp/workshop.tgz .
echo "$GPU_VMS" | while read -r ip name; do
  [[ -z "$ip" ]] && continue
  ( scp -i "$SSH_KEY" -q -o StrictHostKeyChecking=accept-new /tmp/workshop.tgz "$SSH_USER@$ip:/tmp/" &&
    ssh -i "$SSH_KEY" "$SSH_USER@$ip" "mkdir -p ~/workshop && tar -xzf /tmp/workshop.tgz -C ~/workshop && sudo ~/workshop/scripts/node/prep.sh" \
      > "out/prep-$name.log" 2>&1 && echo "OK   $name ($ip)" || echo "FAIL $name ($ip): see out/prep-$name.log" ) &
done
wait
