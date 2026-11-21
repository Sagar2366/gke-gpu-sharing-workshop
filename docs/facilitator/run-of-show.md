# Run of show (3:00–4:30 PM)

You drive everything from your laptop, following the **[codelab](../codelabs/workshop.md)** on the big screen.
Two terminals: **T1** for commands (big font), **T2** for `kubectl get pods -o wide -w`. Run `source scripts/demo/env.sh` in both.

**The day before:** codelab step 2 (`00-check.sh`, `01-prep.sh`). **At 2:30:** `00-check.sh` again; create the 3 VMs if you deleted them.

| Clock | Min | Codelab step | Land this point |
|---|---|---|---|
| 3:00 | 5 | **1 · Introduction** | GPUs are the priciest nodes; Kubernetes hands them out whole. The six problems we'll hit. |
| 3:05 | 4 | **3 · Build the cluster** | "A control plane in a minute." Image downloads in the background. |
| 3:09 | 5 | **4 · Does it need a GPU?** | CPU: a few TFLOPS. The GPU pod is `Pending`. |
| 3:14 | 8 | **5 · Kubernetes can't see the GPU** | `nvidia-smi` works, the node shows no GPU → device plugin → the pending pod starts itself. Hundreds of TFLOPS. |
| 3:22 | 8 | **6 · One pod, one whole GPU** | Join 2 more nodes live. 4 pods, 3 GPUs: one waits while the GPUs idle at 0%. |
| 3:30 | 18 | **7 · Time-slicing** | 4 slots per GPU. Dosa 4× slower (noisy neighbour). Grafana can't name the culprit. Chai crashes from Idli's memory grab. `UnexpectedAdmissionError` for 2 GPUs. |
| 3:48 | 9 | **8 · MPS** | Quarter of the GPU each; speed steady; memory capped, but softly. |
| 3:57 | 8 | **9 · MIG** | 7 hardware slices; equal steady speeds; a hard memory wall. |
| 4:05 | 14 | **10 · Gemma on vLLM** | A 2 GB model holding 125 GB. The second server crashes. Fix with a budget. Chat, then latency with a noisy neighbour. |
| 4:19 | 5 | **11 · Choose a strategy** | Walk the table. HAMi in one sentence (bonus box). |
| 4:24 | 3 | **12 · Clean up** | `99-cleanup.sh`, then delete the VMs in the Jarvislabs console. |
| 4:27 | 3 | *Q&A* | The repo link and QR code. |

## Start MIG early

`NODE=h200-3 ./scripts/k8s/mode.sh mig` can take a few minutes while the GPU is reconfigured. It's in step 7 so it's ready by step 9.
If it's still not showing `7`, do step 10 (Gemma) first and come back to MIG.

## If you're running late

- **Cut first:** the Grafana task (just say "GPU metrics are per GPU"), the MPS memory task, the bench in step 10.
- **Never cut:** the pending pod starting by itself (5), the noisy neighbour and Chai's crash (7), the vLLM crash (10).

## If something breaks

| Symptom | Fallback |
|---|---|
| `kubectl` times out | Port 6443 blocked: Tailscale app on the laptop, `API_VIA=tailscale` in `demo.conf`, re-run `02-control-plane.sh`. |
| A node doesn't join | `ssh root@<ip> journalctl -u k3s-agent -n 30`; re-run `03-join.sh <name>`. Carry on with the nodes you have. |
| Pods stuck in `ContainerCreating` | The image is still downloading: `./scripts/demo/pulled.sh`. Talk through the YAML (`--show`) meanwhile. |
| MIG never reaches 7 | Show the MIG step as slides; MIG mode may not be allowed in that VM. |
| Grafana won't open | `kubectl -n monitoring port-forward svc/monitoring-grafana 3000:80`, then `http://localhost:3000`. |
