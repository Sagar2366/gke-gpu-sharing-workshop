#!/usr/bin/env bash
# serve.sh: run the workshop site locally at http://localhost:8000 (live-reloads on edit).
#   ./serve.sh            # local only
#   ./serve.sh lan        # share it on the venue network: http://<your-laptop-ip>:8000
set -euo pipefail
cd "$(dirname "$0")"
if [[ ! -d .venv ]]; then
  python3 -m venv .venv
  .venv/bin/pip install -q -r requirements.txt
fi
# Vendor Mermaid once (diagrams then work offline; course.js falls back to the CDN otherwise)
MMD=docs/javascripts/vendor/mermaid.min.js
if [[ ! -s "$MMD" ]]; then
  mkdir -p "$(dirname "$MMD")"
  curl -fsSL https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.min.js -o "$MMD" \
    && echo "downloaded Mermaid to $MMD" || { rm -f "$MMD"; echo "could not download Mermaid; diagrams will load from the CDN"; }
fi
addr="127.0.0.1:8000"; [[ "${1:-}" == "lan" ]] && addr="0.0.0.0:8000"
exec .venv/bin/mkdocs serve -a "$addr"
