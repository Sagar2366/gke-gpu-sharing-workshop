# One GPU, Four Teams: hands-on GPU sharing on Kubernetes

GPUs are the most expensive machines in a cluster, and giving every workload a whole one isn't always necessary.
We build a Kubernetes cluster from **3 Jarvislabs H200 GPU VMs**, all from a laptop, and then hit the real problems one by one:
how Kubernetes exposes and hands out a GPU, **time-slicing**, **NVIDIA MPS** and **multi-instance GPU (MIG)**, a noisy neighbour
on purpose, the gotchas that surprise teams, and **Gemma served with vLLM** on a shared GPU.

```mermaid
flowchart LR
  L["Laptop<br/>kubectl + scripts"] -- "SSH + kubectl" --> CP
  subgraph JL["Jarvislabs: 3 × H200, linked by Tailscale"]
    CP["h200-1<br/>control plane + GPU"]
    N2["h200-2<br/>GPU"]
    N3["h200-3<br/>GPU"]
  end
```

| # | Problem we hit | Fix |
|---|---|---|
| 1 | Does this app need a GPU? | measure it: CPU vs GPU |
| 2 | Kubernetes can't see the GPU | the **device plugin** (NVIDIA GPU Operator) |
| 3 | One idle pod takes a whole GPU, others wait | **time-slicing** |
| 4 | Time-slicing: noisy neighbour, no memory limits, one shared GPU per pod | **MPS**: caps per pod |
| 5 | MPS limits are soft | **MIG**: hardware slices |
| 6 | Model servers grab 90% of the GPU's memory | a memory budget per server |

**The four teams:** :material-food: **Dosa** (chat assistant) · :material-rice: **Idli** (greedy batch job) ·
:material-cookie: **Vada** (notebook) · :material-tea: **Chai** (evaluations). Each team's work is a pod named after it.

**You need:** 3 × H200 **VMs** on Jarvislabs with your SSH key · a laptop with `kubectl`, `helm`, `jq` · a free
**Tailscale** account · a **Hugging Face** token with Gemma access · this repo.

**Time:** 90 minutes live, plus ~15 minutes of prep the day before.

## Prepare (the day before)

!!! step "Get the repo and the laptop tools"
    ```bash
    # the workshop repo, with every script used below
    git clone https://github.com/YOUR-ORG/gke-gpu-sharing-workshop.git && cd gke-gpu-sharing-workshop
    # kubectl, helm and jq (macOS)
    brew install kubectl helm jq
    ```

!!! step "Describe your 3 VMs"
    ```bash
    # your settings: VM public IPs + names, SSH key, Tailscale auth key
    cp scripts/demo/demo.conf.example scripts/demo/demo.conf && open -e scripts/demo/demo.conf
    ```

    Tailscale key: [login.tailscale.com](https://login.tailscale.com) → **Settings → Keys → Generate auth key** (tick *Reusable*).

!!! step "Check everything"
    ```bash
    # your Hugging Face token, only kept in this terminal
    export HF_TOKEN=hf_...
    # checks laptop tools, SSH to each VM, and each VM's GPU
    ./scripts/demo/00-check.sh
    ```

    !!! see "You should see"
        `OK` for every line, e.g. `h200-1: NVIDIA H200, 143771 MiB`.

!!! step "Prepare the VMs"
    ```bash
    # on all 3 VMs: copy the repo, install the NVIDIA container toolkit + helm, join Tailscale (~5 min)
    ./scripts/demo/01-prep.sh
    ```

    !!! see "You should see"
        `OK   h200-1  tailscale 100.x.y.z` for all three.

    ??? failure "FAIL: driver missing"
        The log asks for a reboot: `ssh root@<ip> reboot`, wait a minute, run `01-prep.sh` again.

## Build the cluster

!!! step "Start Kubernetes"
    ```bash
    # workshop settings for this terminal (run in every new terminal)
    source scripts/demo/env.sh
    # your Hugging Face token (stored in the cluster as a secret for Gemma)
    export HF_TOKEN=hf_...
    # install k3s (a small, certified Kubernetes) on h200-1 and point kubectl at it (~1 min)
    ./scripts/demo/02-control-plane.sh
    # the machines in the cluster
    kubectl get nodes
    ```

    !!! see "You should see"
        `h200-1   Ready   control-plane`. The ~10 GB workshop image is now downloading; `./scripts/demo/pulled.sh` shows progress.

    ??? failure "kubectl times out"
        Port 6443 on the VM's public IP is probably blocked. Install the Tailscale app on your laptop (same account), set
        `API_VIA=tailscale` in `demo.conf`, and run `02-control-plane.sh` again.

## Problem 1: does it need a GPU?

!!! step "Run the work on the CPU"
    ```bash
    # big matrix multiplications on the CPU only (no GPU requested)
    ./scripts/k8s/pod.sh burn-cpu
    # its speed, printed every 5 s (Ctrl+C to stop watching)
    kubectl logs -f burn-cpu
    ```

    !!! see "You should see"
        `... on CPU (N cores)` and **a few TFLOPS**. Remember the number.

!!! step "Ask for a GPU"
    ```bash
    # the same work, asking for nvidia.com/gpu: 1
    ./scripts/k8s/pod.sh burn-gpu
    # is it running? and if not, why?
    kubectl get pod burn-gpu; kubectl describe pod burn-gpu | tail -2
    ```

    !!! see "You should see"
        `Pending` and `0/1 nodes are available: 1 Insufficient nvidia.com/gpu`.

    ??? question "Show the YAML"
        ```bash
        # every pod.sh pod is plain YAML; --show prints it instead of creating it
        ./scripts/k8s/pod.sh burn-gpu --show
        ```

## Problem 2: Kubernetes can't see the GPU

!!! problem "The machine has a GPU, but Kubernetes doesn't know"
    ```bash
    # the VM itself sees its H200...
    ssh root@$CP_IP nvidia-smi -L
    # ...but the node advertises no nvidia.com/gpu
    kubectl describe node h200-1 | grep -A6 Allocatable
    ```

!!! solution "Fix: a device plugin (NVIDIA GPU Operator)"
    ```bash
    # install NVIDIA's device plugin, GPU labels, DCGM metrics and MIG manager (~3 min)
    ./scripts/k8s/gpu-operator.sh
    # the node now advertises 1 GPU
    kubectl get node h200-1 -o jsonpath='{.status.allocatable.nvidia\.com/gpu}{"\n"}'
    # and the pending pod starts on its own
    kubectl get pod burn-gpu -w
    ```

!!! step "CPU vs GPU, and how the GPU got into the pod"
    ```bash
    # the same work on the GPU
    kubectl logs burn-gpu | tail -2
    # the GPU the device plugin assigned to this pod
    kubectl exec burn-gpu -- nvidia-smi -L
    # tidy up
    kubectl delete pod burn-cpu burn-gpu
    ```

    !!! see "You should see"
        **Hundreds** of TFLOPS vs a few on the CPU. That's why we pay for GPUs.

!!! takeaway "How Kubernetes exposes a GPU"
    The **driver** is on the machine. The **device plugin** advertises `nvidia.com/gpu: N` on the node. A pod asks for a **whole number**;
    the scheduler just **counts**. The **container runtime** plugs the chosen GPU into the container.

## Problem 3: one pod, one whole GPU

!!! step "Add the other two GPU machines"
    ```bash
    # join h200-2 and h200-3 to the cluster (~1 min each)
    ./scripts/demo/03-join.sh h200-2
    ./scripts/demo/03-join.sh h200-3
    # every GPU in "exclusive" mode: 1 GPU = 1 pod
    ./scripts/k8s/mode.sh exclusive
    ```

    !!! see "You should see"
        `h200-1 1`, `h200-2 1`, `h200-3 1` in the GPU column.

!!! step "Four teams, three GPUs"
    ```bash
    # each team starts a pod that holds a GPU and does nothing (like an open notebook)
    ./scripts/k8s/pod.sh hold dosa idli vada chai
    # where did they land?
    kubectl get pods -o wide
    ```

    !!! see "You should see"
        Three `Running`, **one per node**, and one `Pending` (`Insufficient nvidia.com/gpu`).

!!! step "How busy are those GPUs?"
    ```bash
    # utilisation of the GPU that Dosa's pod is holding
    kubectl exec hold-dosa -- nvidia-smi --query-gpu=utilization.gpu,memory.used --format=csv
    # clean up
    kubectl delete pod -l app=hold
    ```

    !!! see "You should see"
        `0 %` and almost no memory used.

!!! problem "One idle pod holds an entire H200"
    Kubernetes hands out GPUs **whole**: whole numbers, first come first served, knowing nothing about how busy a GPU is.

## Strategy 1: time-slicing

!!! step "Give each machine a sharing strategy"
    ```bash
    # h200-1: time-slicing, 4 pods take turns on the GPU
    NODE=h200-1 ./scripts/k8s/mode.sh ts
    # h200-2: NVIDIA MPS, 4 pods run together, each capped (next section)
    NODE=h200-2 ./scripts/k8s/mode.sh mps
    # h200-3: MIG, the GPU cut into 7 hardware slices (a few minutes; used later)
    NODE=h200-3 ./scripts/k8s/mode.sh mig
    ```

    !!! see "You should see"
        GPU column: `h200-1 4`, `h200-2 4`, `h200-3 7` (MIG may need a few minutes).

    ??? why "It's just a label"
        Each node's label picks a device plugin config from `scripts/k8s/device-plugin-config.yaml`. One H200 now advertises 4 "GPUs".

!!! step "Dosa alone: the baseline"
    ```bash
    # everything in this section runs on the time-slicing machine
    export TABLE=h200-1
    # Dosa's GPU-hungry job
    ./scripts/k8s/pod.sh burn dosa
    # Dosa's speed (Ctrl+C to stop watching)
    kubectl logs -f burn-dosa
    ```

    !!! see "You should see"
        A steady number, e.g. `620 TFLOPS`. Write it down.

!!! step "Noisy neighbours"
    ```bash
    # the other three teams start the same job on the same GPU
    ./scripts/k8s/pod.sh burn idli vada chai
    # watch Dosa again
    kubectl logs -f burn-dosa
    # proof it's one GPU: all four show the same UUID
    for t in dosa idli vada chai; do kubectl exec burn-$t -- nvidia-smi -L; done
    ```

    !!! see "You should see"
        Dosa drops to about **a quarter**, with the same `GPU-…` UUID in all four pods.

!!! problem "Noisy neighbour"
    Nobody touched Dosa's pod, yet it's 4× slower. With time-slicing **your speed depends on your neighbours**.

!!! step "Watch it in monitoring"
    ```bash
    # Prometheus + Grafana with NVIDIA's GPU dashboard (~3 min, once)
    ./scripts/k8s/monitoring.sh
    # Grafana's address: open it → Dashboards → NVIDIA DCGM Exporter
    echo "http://$CP_IP:30300"
    ```

    !!! see "You should see"
        h200-1 at ~100% utilisation. GPU metrics are **per GPU**: they can't tell you **which team** is causing it.

    ??? failure "Grafana doesn't open"
        Port 30300 may be blocked. Use `kubectl -n monitoring port-forward svc/monitoring-grafana 3000:80` and open `http://localhost:3000`.

!!! step "No memory limits"
    ```bash
    # stop the jobs
    kubectl delete pod -l app=burn
    # Idli grabs 130 GiB of the H200's ~140
    ./scripts/k8s/pod.sh memhog idli 130
    # Chai asks for a modest 20 GiB
    sleep 45; ./scripts/k8s/pod.sh memhog chai 20
    # what happened to Chai?
    sleep 20; kubectl logs memhog-chai | tail -1
    ```

    !!! see "You should see"
        Chai: `OUT OF MEMORY after 9 GiB`. **The polite pod crashes, not the greedy one.**

!!! step "Gotcha: only one shared GPU per pod"
    ```bash
    # one pod asking for 2 time-sliced "GPUs"
    ./scripts/k8s/pod.sh greedy
    # why did it fail?
    sleep 10; kubectl get pod greedy -o jsonpath='{.status.reason}{"\n"}'
    # clean up
    kubectl delete pod --all
    ```

    !!! see "You should see"
        `UnexpectedAdmissionError`. A time-slice is a turn in the queue, not a piece of the chip.

!!! takeaway "Time-slicing"
    **Isolates:** each process's memory addresses and crashes. **Doesn't isolate:** speed, memory, metrics. One shared GPU per pod.
    **Good for:** bursty, trusted work like notebooks and dev/test.

## Strategy 2: NVIDIA MPS

!!! step "What an MPS pod gets"
    ```bash
    # everything in this section runs on the MPS machine
    export TABLE=h200-2
    # print what the GPU looks like from inside an MPS pod
    ./scripts/k8s/pod.sh probe
    sleep 30; kubectl logs probe; kubectl delete pod probe
    ```

    !!! see "You should see"
        About **a quarter of the GPU**: fewer SMs, and a memory cap around 35 GiB.

!!! step "The noisy neighbour test, again"
    ```bash
    # Dosa alone
    ./scripts/k8s/pod.sh burn dosa
    sleep 40; kubectl logs burn-dosa | tail -1
    # three neighbours join
    ./scripts/k8s/pod.sh burn idli vada chai
    sleep 40; kubectl logs burn-dosa | tail -1
    ```

    !!! see "You should see"
        Dosa is capped lower than with time-slicing, but **barely changes** when the others start.

!!! step "Memory is capped too"
    ```bash
    # stop the jobs; Idli tries to grab 50 GiB
    kubectl delete pod -l app=burn; ./scripts/k8s/pod.sh memhog idli 50
    # Idli stops at its own ~35 GiB cap
    sleep 30; kubectl logs memhog-idli | tail -1; kubectl delete pod --all
    ```

!!! problem "MPS limits are soft"
    The caps are environment variables inside the pod (`CUDA_MPS_*`), pods need `hostIPC: true` (pod.sh adds it), and one crashing
    client can affect the others. Fine for **one trusted team**, not a wall.

## Strategy 3: multi-instance GPU (MIG)

!!! step "Seven GPUs from one"
    ```bash
    # everything in this section runs on the MIG machine
    export TABLE=h200-3
    # it now advertises 7 slices
    kubectl get node h200-3 -o jsonpath='{.status.allocatable.nvidia\.com/gpu}{"\n"}'
    # what a slice looks like from inside
    ./scripts/k8s/pod.sh probe
    sleep 30; kubectl logs probe; kubectl delete pod probe
    ```

    !!! see "You should see"
        `MIG 1g.18gb Device 0` and **~17 GiB total**: the pod can't even see the rest of the GPU.

!!! step "Noisy neighbours can't reach you"
    ```bash
    # four jobs, one per slice (smaller matrix to fit a slice)
    MATRIX=4096 ./scripts/k8s/pod.sh burn dosa idli vada chai
    # their speeds
    sleep 40; for t in dosa idli vada chai; do kubectl logs burn-$t | tail -1; done
    ```

    !!! see "You should see"
        Four **equal, steady** numbers. Each slice has its own cores, memory and bandwidth.

!!! step "A hard memory wall"
    ```bash
    # stop the jobs; Idli tries 24 GiB on its 18 GB slice
    kubectl delete pod -l app=burn; ./scripts/k8s/pod.sh memhog idli 24
    # it stops at its slice, and no setting can raise that
    sleep 30; kubectl logs memhog-idli | tail -1; kubectl delete pod --all
    ```

!!! takeaway "MIG"
    **Isolates:** compute, memory, bandwidth and faults, in hardware. **Costs:** big GPUs only (A100, H100, H200…), slice sizes fixed
    up front, one slice per pod.

## Serve Gemma with vLLM on a shared GPU

!!! step "A model server, the default way"
    ```bash
    # back on the time-slicing machine: Dosa's Gemma server with vLLM's defaults
    export TABLE=h200-1
    TEAM=dosa ./scripts/k8s/gemma.sh
    # wait until it's ready (~2-3 min the first time)
    kubectl rollout status deploy/gemma-dosa --timeout=10m
    # how much GPU memory did a 2 GB model take?
    kubectl exec deploy/gemma-dosa -- nvidia-smi --query-gpu=memory.used --format=csv
    ```

    !!! see "You should see"
        About **125 GB** used. vLLM reserves **90% of the GPU** up front, on purpose, to answer fast.

!!! step "A second team tries"
    ```bash
    # Vada's server: same defaults, same GPU
    TEAM=vada ./scripts/k8s/gemma.sh
    # it crashes; read why
    sleep 90; kubectl logs deploy/gemma-vada | grep -i -m1 memory
    ```

    !!! see "You should see"
        `Free memory on device ... is less than desired GPU memory utilization (0.9 ...)`, then `CrashLoopBackOff`.

!!! problem "Model servers preallocate memory"
    Kubernetes put Vada's pod there because a time-slice was free. Nothing checked memory.

!!! solution "Fix: give every server a memory budget"
    ```bash
    # redeploy Dosa with 20% of the GPU (~28 GB); this frees what it was holding
    GPU_UTIL=0.2 TEAM=dosa ./scripts/k8s/gemma.sh && kubectl rollout status deploy/gemma-dosa --timeout=10m
    # then Vada, also 20%
    GPU_UTIL=0.2 TEAM=vada ./scripts/k8s/gemma.sh && kubectl rollout status deploy/gemma-vada --timeout=10m
    ```

!!! step "Talk to it, then add a noisy neighbour"
    ```bash
    # connect the laptop to Dosa's server
    kubectl port-forward svc/gemma-dosa 8000:8000 >/dev/null 2>&1 &
    # ask Gemma something
    curl -s localhost:8000/v1/chat/completions -H 'Content-Type: application/json' -d '{"model":"'$MODEL'","max_tokens":80,"messages":[{"role":"user","content":"Three tips for Silk Board traffic?"}]}' | jq -r '.choices[0].message.content'
    # response time on a quiet GPU
    bash scripts/attendee/bench.sh 5
    # Idli starts a batch job on the same GPU, then time it again
    ./scripts/k8s/pod.sh burn idli; sleep 30; bash scripts/attendee/bench.sh 5
    ```

    !!! see "You should see"
        Answers get **slower** with the batch job on the same time-sliced GPU. For a chat service with speed promises: MPS or MIG.

!!! step "Clean up"
    ```bash
    # stop the port-forward and remove everything we started
    kill %1 2>/dev/null; kubectl delete deploy --all; kubectl delete svc gemma-dosa gemma-vada; kubectl delete pod --all
    ```

## Choose a strategy

| | Time-slicing | MPS | MIG |
|---|---|---|---|
| Speed with neighbours | drops | steady (capped) | steady |
| Memory limit | **none** | yes, soft | yes, hardware |
| GPUs | any NVIDIA | any NVIDIA | A100 / H100 / H200 / B200 |
| Pods per GPU | up to 48 | up to 48 | up to 7 |
| Shared GPUs per pod | **1** | 1 | **1** slice |
| Needs | nothing | `hostIPC: true` | slice size fixed up front |

- **Bursty, trusted, dev/test** → **time-slicing**, and cap memory in each app
- **Many steady jobs from one team** → **MPS**
- **Untrusted tenants or latency promises** → **MIG**
- **Big training jobs** → a **whole GPU**
- **Model servers on any shared GPU** → always set a memory budget (`--gpu-memory-utilization`)

??? note "Bonus: HAMi, enforced memory limits on any GPU"
    [HAMi](https://project-hami.io) (CNCF) lets a pod ask for `nvidia.com/gpumem` (MB) and `nvidia.com/gpucores` (%), and enforces both.

    ```bash
    # switch h200-2 to HAMi (installs it the first time)
    NODE=h200-2 ./scripts/k8s/mode.sh hami
    # Idli asks for 40 GiB but its pod is limited to 20 GB
    export TABLE=h200-2; ./scripts/k8s/pod.sh hami-memhog idli 40
    # it stops at its own 20 GB, enforced
    sleep 30; kubectl logs memhog-idli | tail -1; kubectl delete pod --all
    ```

## Clean up

!!! step "Tear everything down"
    ```bash
    # uninstall k3s and log every VM out of Tailscale
    ./scripts/demo/99-cleanup.sh
    ```

    Then **delete the 3 VMs** in the Jarvislabs console, and revoke the **Tailscale key** and the **Hugging Face token**.

!!! success "Done"
    From three bare GPU machines to a shared GPU cluster: how Kubernetes exposes and hands out GPUs, all three sharing strategies,
    each one broken on purpose, and a real model on a shared GPU. Every command is in this repo to run again.
