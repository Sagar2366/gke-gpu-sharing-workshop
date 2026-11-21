# Run of show (3:00–4:30 PM, 90 minutes)

This plan assumes the **Jarvislabs** cluster built **live** (likely, since GPU quota is still pending). If GKE quota arrives, use the
same timings: show `01-create-cluster.sh` output (pre-built) during the live-build slot instead, and skip the strategy switches.

| Clock | Min | Codelab step | On the projector | Say / do |
|---|---|---|---|---|
| 3:00 | 3 | **1 · Introduction** | Catalog → **Workshop (Jarvislabs)** codelab | GPUs are the priciest nodes; Kubernetes hands them out whole. Introduce Dosa / Idli / Vada / Chai. Show of hands: Kubernetes? GPUs? Reassure beginners. |
| 3:03 | 12 | **2 · Before you begin**: live build | `PAUSE=1 ./scripts/jarvislabs/up.sh` | Narrate each stage ([script](../codelabs/planb-build.md#4)). Attendees open Cloud Shell and clone the repo meanwhile. |
| 3:15 | 5 | **2 · Before you begin**: connect | Cloud Shell | At **CLUSTER READY**: *"run setup.sh now"*, then the hello pod. Helpers check banners. Keep `WATCH=1 status.sh` on a second screen. |
| 3:20 | 8 | **3 · How GKE gives a pod a GPU** | `kubectl describe node` | Point at `nvidia.com/gpu: 4` on a one-GPU node: "the scheduler counts chairs, not the table". |
| 3:28 | 17 | **4 · GPU time-sharing** | Burn logs | Conduct the table: "Dosas, start… Idlis, go!" Then the memory crash: "who crashed, the greedy one or the innocent one?" Skip Extras. |
| 3:45 | 5 | **5 · Monitoring** | Grafana DCGM dashboard (or Cloud Monitoring on GKE) | Find the hottest table. Punchline: "100% busy, but whose fault?" End with **everyone deletes pods**. |
| 3:50 | 2 | *switch* | `04-switch-strategy.sh mps` | While it runs (~1–2 min), explain MPS with the "assigned seats" analogy from the top of step 6. |
| 3:52 | 12 | **6 · NVIDIA MPS** | Probe output vs step 3's | "58 → 14 SMs, 22 → 5.5 GiB, no code changes." Then the env-var override. |
| 4:04 | 6 | **7 · Multi-instance GPU** | **Demo** on the MIG VM | Show `nvidia-smi -L` with MIG slices, a flat TFLOPS line, the memory wall. Meanwhile run `04-switch-strategy.sh ts`. |
| 4:10 | 12 | **8 · Serve Gemma with vLLM** | Dosa's `nvidia-smi` ~20 GiB | "A 2 GB model holding 20 GB." Let Vada's crash happen, fix with `GPU_UTIL=0.2`. Benchmark with/without burn. Skip Extras. |
| 4:22 | 4 | **9 · Finale** | Astronomy Shop → Jaeger → noisy neighbour ON → Grafana | "Same app, same code, same model: only the neighbour changed." |
| 4:26 | 3 | **10–12 · Choose, clean up, congrats** | Decision flowchart | One pass of the flowchart for Dosa and Idli. Everyone runs the clean-up command. Feedback QR. |
| 4:29 | 1 | *Close* | Catalog page | Take-home codelab link; the repo stays up for a week. |

## If you're running late

- **Cut first:** the Extras in every step, and the MPS "two shares" task.
- **Cut second:** step 5 (show the dashboard for 1 minute yourself), and the finale (show one Jaeger trace only).
- **Never cut:** the noisy neighbour (step 4), MPS vs time-sharing (step 6), and the vLLM crash (step 8).

## If something breaks

| Symptom | Fallback |
|---|---|
| A live-build stage fails | Fix and `FROM=<stage> ./scripts/jarvislabs/up.sh`. Worst case `YES=1 reset.sh && up.sh` (~15 min) while you teach step 3 from slides. |
| One table's GPU VM is broken | Move that table to the stage GPU: `kubectl label node <stage-node> workshop.devfest/table=tNN --overwrite`. Skip the finale. |
| Kubeconfig download fails | Check `status.sh` for port 8088; re-run `./scripts/jarvislabs/07-serve-kubeconfigs.sh`. |
| MIG can't be enabled | Show the MIG step as slides plus the flip cards. |
| Monitoring lags | Use `watch-gpu.sh` or screenshots from rehearsal. |

!!! tip "Open with a 30-second teaser"
    At 3:00, show the Astronomy Shop's AI assistant answering a question. Say: *"By 4:30 you'll know how to make this slow, and how to
    stop it happening."* Pay it off in the finale.
