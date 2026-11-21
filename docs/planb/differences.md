# What changes on Plan B

<div class="lesson-head" markdown>
<span class="pill">Plan B · for attendees</span>
<span class="pill time">:material-timer-outline: 2 min read</span>
[Back to Step 2 :material-arrow-right:](../codelabs/gpu-sharing-on-gke.md#1){ .skip }
</div>

!!! abstract "If the organisers said *"we're on Plan B today"*"
    Today's cluster runs on **Jarvislabs GPU machines** instead of Google Kubernetes Engine. You still use **Cloud Shell**, and
    **every command is the same**. Only the few things below behave differently. Look for the orange **Plan B** boxes in the workshop codelab.

## Step by step

| Workshop step | What's different |
|---|---|
| **2 · Before you begin** | Same `setup.sh` command. It downloads your team's access file; the banner says *Plan B backup cluster*. |
| **3 · How GKE gives a pod a GPU** | NVIDIA's software is in the `gpu-operator` namespace (`kubectl get ds -n gpu-operator`). One GPU machine per table. |
| **4 · Time-sharing** | Same experiments. The "two GPUs" error text is different (it comes from NVIDIA's device plugin). |
| **5 · Monitoring** | **Grafana** instead of Cloud Monitoring. [Steps below](#step-5-grafana-instead-of-cloud-monitoring). |
| **6 · MPS** | The organisers switch your table's GPU to MPS at the break. Some MPS details differ; see the box in Step 6. |
| **7 · MIG** | A bigger GPU (e.g. H200) with bigger slices (e.g. `1g.18gb`). May be shown as a demo. |
| **8 · Gemma** | No difference. |
| **9 · Finale** | Same demo; the GPU graphs come from Grafana. |

## Step 5: Grafana instead of Cloud Monitoring

Do Step 5's **first task** ("make some noise") as written, then:

!!! step "Open Grafana"
    ```bash
    echo "$GRAFANA_URL"
    ```

    Open the printed link in a new browser tab. You're signed in automatically as a **viewer**.

    !!! see "You should see"
        The Grafana home page.

!!! step "Open the GPU dashboard"
    **Dashboards → Workshop → NVIDIA DCGM Exporter Dashboard.**

    !!! see "You should see"
        Panels for **GPU utilization**, **framebuffer (memory) used**, temperature and power, one line per GPU.

    !!! why "Why this matters"
        This is **DCGM**, NVIDIA's GPU monitoring, read by Prometheus. It plays the role Cloud Monitoring plays on GKE.

!!! step "Find your table's GPU"
    Your table's GPU is the one at **~100% utilization** with ~12 GiB used (Idli, Chai and Vada are busy, remember?).
    You can also use the terminal:

    ```bash
    bash scripts/attendee/watch-gpu.sh
    ```

    !!! see "You should see"
        GPU busy % and memory per GPU, refreshed every 30 seconds.

!!! step "Try to find out *which team* is using it"
    In Grafana, go to **Explore**, choose **Prometheus**, and run:

    ```text
    DCGM_FI_DEV_GPU_UTIL
    ```

    Look at the labels on each line.

    !!! see "You should see"
        Labels for the **GPU** (UUID, model, host), but no reliable answer to *"which of the four pods is using it?"*.

    !!! why "The gotcha, same as on GKE"
        GPU metrics are **per GPU**. When four pods share a GPU, the GPU can't tell you who's busy. For that you need metrics from
        the workloads themselves.

!!! step "Clean up"
    ```bash
    kubectl delete pod --all
    ```

Then continue with [Step 6](../codelabs/gpu-sharing-on-gke.md#5).
