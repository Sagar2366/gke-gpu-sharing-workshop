# Run of show (3:00–4:30 PM, 90 minutes)

The session is **concepts → real GPUs live → HAMi on laptops**:
[Concepts](../codelabs/concepts.md) · [Lab 1: real GPUs, live](../codelabs/jarvislabs-demo.md) (you) ·
[Lab 2: HAMi on your laptop](../codelabs/hami-laptop.md) (attendees).

## Before the day

- **One week before:** send attendees the link to Lab 2 step 2 (*Before the workshop*): Docker, kind, the image downloads and the
  mock-monitor build. Conference Wi-Fi can't do it for a full room.
- **The day before:** Lab 1 step 2 (*Prepare*) on all 3 VMs.
- **Morning of:** Lab 1 step 3 (*Build the cluster*) up to Cilium, and check the vLLM image is on every VM.
  Do a full dry run of Lab 1 steps 4–11, then reset the pods (`kubectl delete pod,deploy --all`) and labels (see the cheat sheet).

## Timings

Two terminals for Lab 1: **T1** for commands (big font), **T2** for `kubectl get pods -o wide -w`. Run `source ~/gpu-demo.env` in both.

| Clock | Min | Part | Land this point |
|---|---|---|---|
| 3:00 | 3 | Welcome | One GPU, four teams: Dosa, Idli, Vada, Chai. Laptops open, kind installed? |
| 3:03 | 12 | **Concepts** 1–5 | The 5-layer stack; `nvidia-smi` → NVML → driver; the device plugin and whole-number GPUs; 4 ways to share; HAMi's webhook → scheduler → device plugin. |
| 3:15 | 3 | **Lab 1** · Build the cluster | Show the `kubeadm init` and Cilium commands (already run this morning): `kubectl get nodes`. |
| 3:18 | 5 | **Lab 1** · Problems 1–2 | CPU vs GPU; `Pending`; GPU Operator → the pod starts. |
| 3:23 | 4 | **Lab 1** · Problem 3 | `kubeadm join` h200-2 and h200-3 live. 4 pods, 3 GPUs, one waits. |
| 3:27 | 7 | **Lab 1** · Time-slicing | Dosa 4× slower; Chai crashes from Idli's memory; 2 GPUs refused. GKE flag on screen. |
| 3:34 | 4 | **Lab 1** · MPS | Steady speed, soft memory cap. |
| 3:38 | 4 | **Lab 1** · MIG | 7 slices, hard wall. |
| 3:42 | 5 | **Lab 1** · Gemma on vLLM | 125 GB for a 2 GB model; Vada crashes; the budget fix. |
| 3:47 | 5 | **Lab 1** · HAMi | 20 GB limit that holds; Gemma with its own 20 GB. "Now you do the scheduling part." |
| 3:52 | 3 | **Lab 2** · Create your cluster | Helpers walk the room: anyone without the images pairs with a neighbour. |
| 3:55 | 8 | **Lab 2** · Problem 1 + install HAMi | `Pending` → HAMi + two fake A100s → 20 / 81920 / 200. |
| 4:03 | 6 | **Lab 2** · Problems 2–3 | Three teams on two cards; who scheduled them; Chai's `CardInsufficientMemory`. |
| 4:09 | 5 | **Lab 2** · Problem 4 | binpack vs spread. |
| 4:14 | 5 | **Lab 2** · Problem 5 | Reserved vs used; the fake vLLM holds 90%. |
| 4:19 | 3 | **Choose a strategy** | Lab 1's table, all four columns. |
| 4:22 | 2 | **Clean up** | `kind delete cluster --name hami-lab`; you tear down after the session. |
| 4:24 | 6 | *Q&A* | Repo link and QR code. |

**Running late?** Skip Lab 1's MPS section (show the takeaway), and Lab 2's Problem 5 becomes take-home.

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
| `kubectl` from the laptop times out | Port 6443 isn't open to your laptop: `ssh -fN -L 6443:$P1:6443 root@$H1`, and point the kubeconfig at `https://127.0.0.1:6443` (Lab 1 step 3). |
| A node won't join | `ssh root@<ip> journalctl -u kubelet -n 30`; `ssh root@<ip> kubeadm reset -f`, then the `kubeadm join` command again. |
| Pods stuck in `ContainerCreating` | The image is still downloading: `ssh root@<ip> "crictl images | grep vllm"`. Talk through the YAML meanwhile. |
| MIG never reaches 7 | Show the MIG step as slides. |
| Lab 2: an attendee has no images | Pair them with a neighbour; their pulls will take too long on venue Wi-Fi. |
| Lab 2: `hami-mock-device-plugin` not Running | `kubectl -n kube-system get pods | grep mock`, then `kubectl -n kube-system describe pod <that pod>`; usually an image that wasn't `kind load`ed. |
| Grafana won't open | `kubectl -n monitoring port-forward svc/monitoring-grafana 3000:80`, then `http://localhost:3000`. |
