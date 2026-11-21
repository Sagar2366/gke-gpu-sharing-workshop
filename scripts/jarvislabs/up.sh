#!/usr/bin/env bash
# up.sh: the LIVE build, start to finish, in front of the room (~15 min).
#
#   ./scripts/jarvislabs/up.sh            # run everything
#   PAUSE=1 ./scripts/jarvislabs/up.sh    # presenter mode: pause before each stage so you can explain it
#   FROM=3 ./scripts/jarvislabs/up.sh     # resume from stage 3 after a failure
#
# Stages:
#   1  k3s server on the CPU VM                          (~1 min)
#   2  join GPU VMs + load workshop image                (~3 min)
#   3  GPU Operator (tables start in INITIAL_MODE, default exclusive) + monitoring  (~8 min)
#   4  attendee namespaces + kubeconfigs, start serving  (~1 min)
#   5  status check                                      (~1 min)
#
# Before the session: prep-hosts.sh (slow stuff) and 00-doctor.sh must pass.
set -euo pipefail
cd "$(dirname "$0")"
source ./jl.conf
FROM="${FROM:-1}"
T0=$(date +%s)

banner () {
  local n=$1; shift
  printf "\n\033[1;44m  STAGE %s/5  %s  \033[0m   (elapsed %dm%02ds)\n" "$n" "$*" $(( ($(date +%s)-T0)/60 )) $(( ($(date +%s)-T0)%60 ))
  if [[ "${PAUSE:-0}" == "1" ]]; then read -r -p "  press Enter to start this stage... " _; fi
}
run () { local n=$1; shift; [[ $n -lt $FROM ]] && { echo "  (skipping stage $n)"; return; }; "$@"; }

banner 1 "Kubernetes control plane (k3s server)";            run 1 ./01-server.sh
export KUBECONFIG="$PWD/out/admin.kubeconfig"
banner 2 "Join the GPU machines";                             run 2 ./02-gpu-nodes.sh
banner 3 "NVIDIA GPU Operator, sharing configs, monitoring";  run 3 ./03-platform.sh
banner 4 "Attendee access";                                   run 4 bash -c "./06-onboard.sh && ./07-serve-kubeconfigs.sh"
banner 5 "Status";                                            run 5 ./status.sh

printf "\n\033[1;42m  CLUSTER READY in %d min  \033[0m  Attendees can now run:  source scripts/attendee/setup.sh <table> <team>\n" $(( ($(date +%s)-T0)/60 ))
