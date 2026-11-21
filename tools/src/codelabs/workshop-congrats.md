You shared one GPU between four teams in three different ways, and felt the trade-offs first-hand: the noisy neighbour
under time-sharing, the fixed (and not-so-firm) seats of MPS, and the hardware walls of MIG. Then you served a real model on a
shared GPU and saw the same problem show up in a real app's traces.

### What you've learned

- How GKE exposes a GPU to a pod, and why the scheduler only counts "chairs"
- What **time-sharing**, **NVIDIA MPS** and **MIG** each isolate, and what they don't
- Why pods on a shared GPU can ask for only one GPU, and why model servers need an explicit **memory budget**
- How to read GPU metrics, and why they can't tell you **which team** is using a shared GPU
- How to choose a sharing strategy for a real workload

### Take it home

- **[Run the labs on one Jarvislabs GPU VM](jarvislabs-solo.md)**: build the same cluster yourself on a single GPU VM, then play all four teams.
- **[Run it in your own Google Cloud project](own-project.md)**: the same labs on GKE with one cheap L4, using your DevFest credits.
- **[Cheat sheet](../reference/cheatsheet.md)**: every flag, label and command from today on one page.
- **[HAMi](../reference/hami.md)**: the CNCF project that adds requestable, enforced GPU memory and compute limits on top of sharing.
- **[Beyond GKE](../reference/beyond-gke.md)**: how these strategies map to the NVIDIA GPU Operator on any Kubernetes cluster.
- **[What's next: AICR and Agent Substrate](../reference/whats-next.md)**: two new open-source projects just below and just above today's topic.

### Other codelabs

These are standalone, so do them in any order.

- **[GPU sharing foundations](foundations.md)**: CPUs vs GPUs, Kubernetes and GKE basics, the three strategies explained.
- **[Run the labs on one Jarvislabs GPU VM](jarvislabs-solo.md)**: the do-it-yourself version of today's cluster.
- **[Run it in your own Google Cloud project](own-project.md)**: repeat every step on GKE.
- **[The GKE edition of this workshop](gpu-sharing-on-gke.md)** · **[The Jarvislabs edition](gpu-sharing-jarvislabs.md)**: same steps, different cluster.

### Reference docs

- [About GPU sharing strategies in GKE](https://cloud.google.com/kubernetes-engine/docs/concepts/timesharing-gpus)
- [Configure GPU time-sharing](https://cloud.google.com/kubernetes-engine/docs/how-to/timesharing-gpus) · [NVIDIA MPS](https://cloud.google.com/kubernetes-engine/docs/how-to/nvidia-mps-gpus) · [Multi-instance GPUs](https://cloud.google.com/kubernetes-engine/docs/how-to/gpus-multi)
- [Serve Gemma on GKE GPUs with vLLM](https://cloud.google.com/kubernetes-engine/docs/tutorials/serve-gemma-gpu-vllm)
- [NVIDIA MPS documentation](https://docs.nvidia.com/deploy/mps/index.html) · [NVIDIA MIG user guide](https://docs.nvidia.com/datacenter/tesla/mig-user-guide/)
- [OpenTelemetry Demo](https://opentelemetry.io/docs/demo/)

!!! success "Thank you"
    Thanks for sharing a GPU with us at DevFest Bengaluru!
