# Run of show (3:00–4:30 PM, 90 minutes)

**The story:** build a GPU cluster live, then hit one real problem after another and fix it. Attendees follow the
**[workshop codelab](../codelabs/gpu-sharing-jarvislabs.md)**. You type the **On the big screen** commands; they do the tasks.

| Clock | Min | Step | You run (big screen) | Attendees | Land this point |
|---|---|---|---|---|---|
| 3:00 | 3 | **1 · Introduction** | catalog page | listen | "GPUs are the priciest nodes. Let's build a cluster and break it." |
| 3:03 | 17 | **2 · Build the cluster** | `01-server.sh` → `02-gpu-nodes.sh` → `kubectl describe node` (no GPU!) → `03-gpu-operator.sh` → `03b-monitoring.sh` → `06-onboard.sh && 07-serve-kubeconfigs.sh` | open Cloud Shell, clone repo | **Problem:** K8s can't see GPUs. **Fix:** the device plugin. "On GKE, Google runs all this." |
| 3:20 | 8 | **3 · Your first GPU pod** | `WATCH=1 status.sh` on screen 2 | `setup.sh`, probe pod | "You're on your table's L4." |
| 3:28 | 7 | **4 · Problem: whole GPU** | (end) `04-switch-strategy.sh ts` | Dosa holds the GPU; others Pending | **Problem:** an idle pod holds a whole GPU. |
| 3:35 | 15 | **5 · Fix: time-slicing** | Grafana DCGM dashboard at the end | burn ×4, then memhog | **New problems:** noisy neighbour (4× slower), memory crash hits the *innocent* pod. |
| 3:50 | 6 | **6 · MPS and MIG** | `ROLE=stage 04-switch-strategy.sh mps` + `demo.sh mps`; `demo.sh mig`; then `demo.sh clean` + `04-switch-strategy.sh hami` | watch, table talk | MPS: steady but soft caps. MIG: hard walls, big GPUs only. "Neither fits our L4s → HAMi." |
| 3:56 | 15 | **7 · Fix: HAMi** | | probe sees a 4 GB GPU, memhog hits own wall, burn capped | **Fixed:** enforced memory and compute per pod. |
| 4:11 | 12 | **8 · A real model** | | 4 × Gemma/vLLM on one L4, chat, bench | **Fixed:** vLLM's 90% grab becomes 90% of *its* 5 GB. No crashes. |
| 4:23 | 4 | **9 · Choose your fix** | the table | quiz | One line each; gang scheduling in one sentence. |
| 4:27 | 2 | **10 · Clean up** | | delete everything, feedback QR | |
| 4:29 | 1 | *Close* | delete the VMs after | | Take-home codelab link. |

!!! tip "Keep these open"
    Terminal 1: the build/switch commands (big font). Terminal 2: `WATCH=1 ./scripts/jarvislabs/status.sh`. A browser tab with Grafana (`$GRAFANA_URL`).

## If you're running late

- **Cut first:** step 6's MIG demo (say one sentence), every **Extra** task, the bench in step 8.
- **Cut second:** step 5's memory crash (describe it), step 9's quiz.
- **Never cut:** the invisible GPU (2), the Pending pods (4), the noisy neighbour (5), HAMi's memory wall (7).

## If something breaks

| Symptom | Fallback |
|---|---|
| A build stage fails | Fix and re-run that script (each is safe to re-run). Worst case: `YES=1 reset.sh && up.sh` (~15 min) while you explain step 4 on slides. |
| A table's GPU VM is broken | Give that table the stage GPU: `kubectl label node <stage-node> workshop.devfest/table=tNN --overwrite`. Skip the MPS demo. |
| HAMi switch is slow (image pulls) | Talk through step 7's YAML while it finishes; check `kubectl -n kube-system get pods`. |
| HAMi misbehaves | Switch back with `04-switch-strategy.sh ts` and run step 8 with `--gpu-memory-utilization=0.2` (the old way, which also teaches the problem). |
| MIG can't be enabled | Show step 6's MIG tab as a slide. |
| Kubeconfig download fails | `status.sh` → port 8088; re-run `07-serve-kubeconfigs.sh`. |
