# Run of show (3:00–4:30 PM, 90 minutes)

There are two ways to run the session on Jarvislabs:

- **The 3-VM kubeadm demo** (you drive everything from your laptop): follow the **[Jarvislabs demo codelab](../codelabs/jarvislabs-demo.md)**. Its timings are below in *Demo timings*.
- **The live-built table cluster** (attendees do tasks on their table's GPU): follow the **[workshop codelab](../codelabs/gpu-sharing-jarvislabs.md)**, timings in *Table cluster timings*.

## Demo timings (3 VMs, kubeadm)

Two terminals: **T1** for commands (big font), **T2** for `kubectl get pods -o wide -w`. Run `source scripts/demo/env.sh` in both.
**The day before:** codelab step 2. **At 2:30:** `./scripts/demo/00-check.sh`.

| Clock | Min | Step | Land this point |
|---|---|---|---|
| 3:00 | 5 | **1 · Introduction** | GPUs are the priciest nodes; Kubernetes hands them out whole. The six problems we'll hit. |
| 3:05 | 9 | **3 · Build the cluster** | `kubeadm init` on VM 1 → kubectl on the laptop → node `NotReady` → Cilium → `Ready`. |
| 3:14 | 4 | **4 · Does it need a GPU?** | CPU: a few TFLOPS. The GPU pod is `Pending`. |
| 3:18 | 7 | **5 · Kubernetes can't see the GPU** | `nvidia-smi` works, the node shows no GPU → device plugin → the pending pod starts by itself. |
| 3:25 | 8 | **6 · One pod, one whole GPU** | `kubeadm join` 2 more VMs live. 4 pods, 3 GPUs: one waits while the GPUs idle at 0%. |
| 3:33 | 16 | **7 · Time-slicing** | Dosa 4× slower. Grafana can't name the culprit. Chai crashes from Idli's memory grab. 2 shared GPUs refused. |
| 3:49 | 8 | **8 · MPS** | A quarter of the GPU each; steady speed; memory capped, softly. |
| 3:57 | 7 | **9 · MIG** | 7 hardware slices; equal speeds; a hard memory wall. |
| 4:04 | 13 | **10 · Gemma on vLLM** | 125 GB for a 2 GB model; the second server crashes; fix with a budget; latency with a noisy neighbour. |
| 4:17 | 4 | **11 · Choose a strategy** | The table, plus HAMi in one sentence. |
| 4:21 | 3 | **12 · Clean up** | `kubeadm reset` on each VM, then delete the VMs. |
| 4:24 | 6 | *Q&A* | Repo link and QR code. |

## Table cluster timings (live-built, one GPU per table)

| Clock | Min | Step | You run (big screen) | Land this point |
|---|---|---|---|---|
| 3:00 | 3 | **1 · Introduction** | catalog page | "Let's build a cluster and break it." |
| 3:03 | 17 | **2 · Build the cluster** | `01-server.sh` → `02-gpu-nodes.sh` → `kubectl describe node` (no GPU!) → `03-gpu-operator.sh` → `03b-monitoring.sh` → `06-onboard.sh && 07-serve-kubeconfigs.sh` | K8s can't see GPUs → device plugin. |
| 3:20 | 8 | **3 · Your first GPU pod** | `WATCH=1 status.sh` on screen 2 | "You're on your table's L4." |
| 3:28 | 7 | **4 · Problem: whole GPU** | (end) `04-switch-strategy.sh ts` | An idle pod holds a whole GPU. |
| 3:35 | 15 | **5 · Fix: time-slicing** | Grafana at the end | Noisy neighbour; memory crash hits the innocent pod. |
| 3:50 | 6 | **6 · MPS and MIG** | `demo.sh mps`, `demo.sh mig`, then `04-switch-strategy.sh hami` | Soft caps vs hard walls. |
| 3:56 | 15 | **7 · Fix: HAMi** | | Enforced memory and compute per pod. |
| 4:11 | 12 | **8 · A real model** | | vLLM's 90% becomes 90% of its own 5 GB. |
| 4:23 | 4 | **9 · Choose your fix** | | One line each; gang scheduling in one sentence. |
| 4:27 | 3 | **10 · Clean up** + close | | |

## If something breaks

| Symptom | Fallback |
|---|---|
| `kubectl` from the laptop times out | Port 6443 isn't open to your laptop: set `API_VIA=tunnel` in `demo.conf` and run `./scripts/demo/tunnel.sh` (an SSH tunnel). |
| A node won't join | `ssh root@<ip> journalctl -u kubelet -n 30`; `kubeadm reset -f` on that VM and re-run `03-join.sh <name>`. |
| Pods stuck in `ContainerCreating` | The image is still downloading: `./scripts/demo/pulled.sh`. Talk through the YAML (`--show`) meanwhile. |
| MIG never reaches 7 | Show the MIG step as slides. |
| Grafana won't open | `kubectl -n monitoring port-forward svc/monitoring-grafana 3000:80`, then `http://localhost:3000`. |
