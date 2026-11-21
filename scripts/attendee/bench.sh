#!/usr/bin/env bash
# bench.sh: send N chat requests to your Gemma server and print latency for each.
#
#   kubectl port-forward svc/gemma 8000:8000 &     # in another tab, or backgrounded
#   bash scripts/attendee/bench.sh 10
set -euo pipefail
N="${1:-10}"
URL="${URL:-http://127.0.0.1:8000}"
MODEL="${MODEL:-google/gemma-3-1b-it}"

total=0
for i in $(seq 1 "$N"); do
  t=$(curl -s -o /dev/null -w '%{time_total}' "$URL/v1/chat/completions" \
        -H 'Content-Type: application/json' \
        -d "{\"model\":\"$MODEL\",\"max_tokens\":128,\"temperature\":0,
             \"messages\":[{\"role\":\"user\",\"content\":\"Explain GPU time-sharing to a Bengaluru auto driver in 5 sentences.\"}]}")
  printf "request %2d  %6.2f s\n" "$i" "$t"
  total=$(echo "$total + $t" | bc -l)
done
printf -- "-----------------\naverage     %6.2f s\n" "$(echo "$total / $N" | bc -l)"
