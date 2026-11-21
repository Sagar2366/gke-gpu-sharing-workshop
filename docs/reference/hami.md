# HAMi: memory and compute limits for shared GPUs

In Step 4 you saw time-sharing's biggest weakness: **no memory limits**, so Idli's 20 GiB grab crashed Chai.
In Step 6, MPS added limits, but they were **settings the pod could change**. **[HAMi](https://project-hami.io)** is an open-source
project that tackles exactly this gap. It's a **CNCF Incubating** project (Heterogeneous AI Computing Virtualization Middleware).

!!! info "Not part of the live labs"
    The labs use only what GKE provides out of the box. HAMi replaces the GPU device plugin with its own, so it's a
    take-home topic, ideal if you run your own Kubernetes on GPU VMs.

## What HAMi adds

<p class="hint">Select each tab to learn more.</p>

=== "Fractional requests"

    Instead of "one whole GPU" or "one chair", a pod can ask for **an amount of GPU memory and a share of compute**:

    ```yaml
    resources:
      limits:
        nvidia.com/gpu: 1          # one (virtual) GPU
        nvidia.com/gpumem: 4000    # 4000 MB of GPU memory
        nvidia.com/gpucores: 30    # about 30% of the GPU's compute
    ```

    The scheduler now places pods by **memory and compute**, not just by chair count. That fixes the Step 3 problem where the
    scheduler knew nothing about what each chair got.

=== "Enforced limits"

    HAMi's in-container layer (HAMi-core) sits between your program and the GPU driver and **enforces** those limits.
    A pod asking for 4000 MB gets an out-of-memory error at its **own** limit, not at the whole GPU's. That's the Step 4 crash,
    fixed, without changing application code.

=== "Scheduling policies"

    Policies such as **binpack** (fill one GPU before using the next) or **spread** (balance across GPUs), at node and GPU level.
    It integrates with Volcano and Kueue, offers dynamic MIG support, and supports devices from several vendors beyond NVIDIA.

=== "Observability"

    Per-device **allocation and usage metrics** and Grafana dashboards. That fills part of the Step 5 gap
    ("the GPU is busy, but who's using it?").

## How it compares with what you used today

| | GKE time-sharing | GKE MPS | GKE MIG | **HAMi** |
|---|---|---|---|---|
| Ask for an amount of memory | :material-close: | :material-close: (fixed ¼ share) | fixed slice sizes | :material-check: any amount |
| Memory limit enforced | :material-close: | soft (env var) | :material-check-all: hardware | :material-check: software |
| Compute share | turns | SM % cap | hardware | % cap |
| Scheduler knows memory/compute | :material-close: | :material-close: | slice size only | :material-check: |
| Managed by GKE | :material-check: | :material-check: | :material-check: | :material-close: you install it |
| Isolation strength | software | software | **hardware** | software |

!!! warning "Same trust rule"
    HAMi's limits are enforced in software. They're much harder to sidestep than an environment variable, but for workloads
    that **must not trust each other**, hardware isolation (MIG) is still the strongest option.

## Try it at home (outside GKE)

On a GPU VM with **root access** (for example a Jarvislabs, Lambda or on-prem VM) running k3s, with the NVIDIA driver and
NVIDIA Container Toolkit installed, the getting-started flow looks like this:

```bash
# label the GPU node so HAMi manages it
kubectl label nodes <your-node> gpu=on

# install HAMi with Helm
helm repo add hami-charts https://project-hami.github.io/HAMi/
helm install hami hami-charts/hami -n kube-system
```

Then re-run the **Step 4 memory experiment** with HAMi limits: give Idli `nvidia.com/gpumem: 8000` and watch `memhog.py`
stop at Idli's own limit while Chai's pod keeps working.

!!! tip "Check the official steps"
    Prerequisites and chart values change between releases. Follow
    [HAMi's install guide](https://project-hami.io/docs/next/get-started/deploy-with-helm) and the
    [prerequisites](https://project-hami.io/docs/next/installation/prerequisites). For hands-on practice, the
    [HAMi workshop](https://workshop.project-hami.io/) has its own step-by-step labs.

!!! note "What about GKE?"
    HAMi replaces the GPU device plugin, and GKE manages its own. We haven't tested HAMi on GKE for this workshop, so check
    the HAMi docs and community before you try it on a GKE cluster.

!!! takeaway "Key takeaway"
    - HAMi adds what GKE's time-sharing lacks: **ask for an amount of GPU memory and compute, and have it enforced.**
    - The scheduler places pods by memory and compute, not just chair count.
    - It's a software limit: great inside one organisation, but use MIG when tenants can't trust each other.

**Links:** [project-hami.io](https://project-hami.io) · [GitHub: Project-HAMi/HAMi](https://github.com/Project-HAMi/HAMi) · [HAMi workshop](https://workshop.project-hami.io/)
