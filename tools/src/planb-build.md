# Build the workshop cluster on Jarvislabs

!!! abstract "What you'll do"
    Get the GPU machines ready **the day before** (all the slow parts), then build the Kubernetes cluster **live in front of the room**
    in about 15 minutes with one command. Everything runs from your laptop or Cloud Shell, using the scripts in `scripts/jarvislabs/`.

    | When | What | Time |
    |---|---|---|
    | **T-3 days** | Rent the VMs, fill in `jl.conf`, run `00-doctor.sh` | 30 min |
    | **T-1 day** | `prep-hosts.sh` (driver, toolkit, 10 GB image, Gemma cache), then a full **rehearsal** of the live build, then `reset.sh` | 2 h |
    | **3:00 PM, live** | `PAUSE=1 ./scripts/jarvislabs/up.sh` on the projector | 12–15 min |
    | **4:30 PM** | Delete the VMs | 5 min |

!!! info "Why build it live?"
    It's a great teaching moment: attendees see exactly what GKE manages for them (control plane, GPU driver, device plugin, sharing
    config), and they clone the same repo, so everyone is on the same page. The slow parts are done beforehand, so the live part is
    short and predictable. If it fails on stage, you can rebuild fast (see the last step).

## Rent the machines

!!! step "Create the VMs on Jarvislabs"
    In the Jarvislabs console create **VMs** (not template/container instances, since we need root and Docker), all in the **same region**:

    | Role | How many | Suggested |
    |---|---|---|
    | k3s server (+ monitoring, + finale shop) | 1 | CPU VM, 8 vCPU / 32 GB, Ubuntu |
    | Table GPUs | 1 per table of 4 | 1 × **L4** each |
    | Stage GPU (finale) | 1 | 1 × L4 |
    | MIG GPU (MIG step, as a demo) | 1 | 1 × **H200** or H100 |

    Add your **SSH public key** to all of them, and note every IP address.

    !!! why "Why VMs?"
        Container instances can't run Kubernetes, and only a VM with root can switch a GPU into MIG mode.

!!! step "Open the network paths"
    VMs → server: **6443/tcp** and **8472/udp** (pod network). Attendees → server: **6443**, **8088**, **30300**, **30090** (tcp).
    Use Jarvislabs private networking between VMs if available; otherwise public IPs and the VM firewall.

!!! step "Fill in the inventory"
    ```bash
    git clone https://github.com/YOUR-ORG/gke-gpu-sharing-workshop.git && cd gke-gpu-sharing-workshop
    cp scripts/jarvislabs/jl.conf.example scripts/jarvislabs/jl.conf
    openssl rand -hex 8        # use this as KC_SECRET
    ```

    Edit `scripts/jarvislabs/jl.conf`: SSH key, server IPs, one line per GPU VM (`<ip> <table> <role>`), `KC_SECRET`, and the attendee CSV path.

    !!! see "You should see"
        A `GPU_NODES` list like `203.0.113.21 t01 table`, …, `203.0.113.30 t00 stage`, `203.0.113.40 - mig`.

!!! step "Publish the attendee settings now"
    In `workshop.conf`, inside the Plan B block, set the server's **public IP** and your **KC_SECRET**:

    ```bash
    export KUBECONFIG_BASE_URL="http://<server-public-ip>:8088/<KC_SECRET>"
    export PROM_URL="http://<server-public-ip>:30090"
    export GRAFANA_URL="http://<server-public-ip>:30300"
    export MIG_PARTITION="1g.18gb"        # = MIG_PROFILE in jl.conf
    ```

    Make sure `PLATFORM="jarvislabs"`. Commit and **push**. Because the IP and secret are fixed, nothing needs changing during the session.

    !!! warning "Never commit jl.conf or tokens"
        `jl.conf` and `scripts/jarvislabs/out/` are in `.gitignore`. Keep `HF_TOKEN` in your shell only.

!!! step "Run the doctor"
    ```bash
    export HF_TOKEN=hf_...
    ./scripts/jarvislabs/00-doctor.sh
    ```

    !!! see "You should see"
        `OK` for your tools, SSH to every VM and each GPU's name. `WARN` lines about the toolkit, image, Gemma or ports are expected until the next steps.

## Prepare the hosts (the day before)

!!! step "Do all the slow parts"
    ```bash
    ./scripts/jarvislabs/prep-hosts.sh
    ```

    On every GPU VM in parallel: NVIDIA driver, container toolkit, the ~10 GB workshop image (saved as a tarball) and the Gemma model cache.

    !!! see "You should see"
        `OK <ip> (...)` for every VM. Logs are in `scripts/jarvislabs/out/logs/`.

    ??? failure "REBOOT <ip>"
        The driver was missing and has been installed. Reboot that VM (`ssh root@<ip> reboot`), wait a minute, and re-run. Finished steps are skipped.

!!! step "Check again"
    ```bash
    ./scripts/jarvislabs/00-doctor.sh
    ```

    !!! see "You should see"
        No `FAIL`, and no `WARN` except the four **ports** (they open when the cluster is up).

## Rehearse the live build

!!! step "Build it once, end to end"
    ```bash
    ./scripts/jarvislabs/up.sh
    ```

    !!! see "You should see"
        Five blue `STAGE` banners and a green **CLUSTER READY in N min**. Note the time: ______ min.

!!! step "Test as an attendee"
    In a fresh Cloud Shell (a second Google account is ideal): clone the repo, `source scripts/attendee/setup.sh t01 dosa`, then do the
    workshop's **Before you begin**, **How GKE gives a pod a GPU** and **GPU time-sharing** steps. Then test the strategy switch:

    ```bash
    ./scripts/jarvislabs/04-switch-strategy.sh mps && ./scripts/jarvislabs/04-switch-strategy.sh ts
    ```

!!! step "Wipe it for the real thing"
    ```bash
    ./scripts/jarvislabs/reset.sh
    ```

    Removes Kubernetes from every VM but **keeps** the prep (driver, image, model), so the live build stays fast.

## Build it live (3:00 PM)

!!! step "Pre-flight, 30 minutes before"
    ```bash
    ./scripts/jarvislabs/00-doctor.sh
    ```

    All required checks pass. Open two terminals on the projector: one for the build, one for `WATCH=1 ./scripts/jarvislabs/status.sh` afterwards.

!!! step "Run the build in presenter mode"
    ```bash
    export HF_TOKEN=hf_...
    PAUSE=1 ./scripts/jarvislabs/up.sh
    ```

    It pauses before each stage so you can explain it. While it runs, attendees open Cloud Shell and clone the repo
    (the workshop's **Before you begin** step).

    | Stage | Say this while it runs |
    |---|---|
    | 1 · k3s server | "This is the control plane: API server, scheduler. On GKE, Google runs this for you." |
    | 2 · Join GPU nodes | "Every table's L4 joins as a node. The driver's already on them; GKE installs that for you too." |
    | 3 · GPU Operator | "The **device plugin** is what tells Kubernetes a node has GPUs. Its config decides sharing: `ts4` means one GPU shows up as 4." |
    | 4 · Attendee access | "Each of you gets your own namespace and an access file." |
    | 5 · Status | Point at `GPU=4` on every table node: "one physical GPU, four chairs". |

    !!! see "You should see"
        **CLUSTER READY**. Tell the room: *"Run `source scripts/attendee/setup.sh <table> <team>` now."*

    ??? failure "A stage failed"
        Read the last lines; fix the cause; resume with `FROM=<stage> ./scripts/jarvislabs/up.sh`. Every stage is safe to re-run.
        Worst case: `YES=1 ./scripts/jarvislabs/reset.sh && ./scripts/jarvislabs/up.sh` rebuilds from scratch in ~15 min while you
        present the time-sharing concepts.

## During the workshop

!!! step "Switch the table GPUs between steps"
    Each table has one GPU VM, so you switch it between strategies:

    | When | Run |
    |---|---|
    | End of **Watch it in your monitoring** (everyone deletes pods) | `./scripts/jarvislabs/04-switch-strategy.sh mps` |
    | During **Multi-instance GPU** (a demo on the MIG VM) | `./scripts/jarvislabs/04-switch-strategy.sh ts` |

    Each switch takes ~1–2 minutes and deletes any leftover attendee pods on table GPUs.

!!! step extra "Finale"
    ```bash
    STAGE_TABLE=t00 ./scripts/facilitator/07-otel-demo.sh
    ```

    Run it right after the cluster is ready (it pulls images in the background). Show Grafana's DCGM dashboard instead of Cloud Monitoring.

## Tear down (4:30 PM)

!!! step "Delete everything"
    1. **Delete all Jarvislabs VMs** in the console. This removes the cluster, tokens and kubeconfig server.
    2. Revoke the Hugging Face token.

## Rehearsal checklist

- [ ] VMs give **root SSH** and have (or can install) **Docker** and the NVIDIA driver.
- [ ] `00-doctor.sh` shows no FAIL; `prep-hosts.sh` finishes on every VM.
- [ ] `up.sh` finishes, and the time is noted: ______ min (target ≤ 15).
- [ ] From Cloud Shell: kubeconfig download works, `kubectl` reaches 6443, Grafana opens at `$GRAFANA_URL`.
- [ ] Table nodes show `GPU=4`; after `04-switch-strategy.sh mps` they still show 4 and an MPS control-daemon pod runs.
- [ ] MIG node shows **7** slices and a probe prints a `MIG` device. If MIG mode can't be enabled in the VM, show the MIG step as slides.
- [ ] All workshop steps pass as an attendee, including four Gemma servers at 0.2 and the `UnexpectedAdmissionError`.
- [ ] `reset.sh` + `up.sh` rebuild works (your plan if something breaks on stage).
- [ ] VM IPs survive a pause/resume, **or** you keep VMs running from the rehearsal to the session.
