# Step 5 · Watch it in Cloud Monitoring

<div class="lesson-head" markdown>
<span class="pill">Module 2 · Step 5 of 7</span>
<span class="pill time">:material-timer-outline: 10 min</span>
<span class="pill who">:material-account: everyone on their own</span>
[Skip to Step 6 :material-arrow-right:](04-mps.md){ .skip }
</div>

<!-- only:gke -->
!!! abstract "What you'll do"
    Open Google Cloud's metrics page, find the GPU your table has been hammering, and discover what
    those charts **can't** tell you.

GKE automatically sends GPU numbers to **Cloud Monitoring**. For shared GPUs you get three, **per node**:

| Metric | Meaning |
|---|---|
| `duty_cycle` | % of time the GPU was busy (0–100) |
| `memory_used` | GPU memory in use, in bytes |
| `memory_total` | GPU memory size, in bytes |

!!! warning "Metrics are a few minutes behind"
    GKE samples about once a minute, and charts lag 1–3 minutes. So **start the load first**, then go and look.

<!-- /only -->
<!-- only:jarvislabs -->
!!! abstract "What you'll do"
    Open **Grafana**, find the GPU your table has been hammering, and discover what those charts **can't** tell you.

The cluster's **NVIDIA DCGM exporter** reads every GPU's numbers, **Prometheus** stores them, and **Grafana** draws them.
It plays the role Cloud Monitoring plays on GKE. The ones we use:

| Metric | Meaning |
|---|---|
| `DCGM_FI_DEV_GPU_UTIL` | % of time the GPU was busy (0–100) |
| `DCGM_FI_DEV_FB_USED` | GPU memory ("framebuffer") in use, in MiB |

<!-- /only -->

!!! step ":material-rice: Idli + :material-tea: Chai · Make some noise"
    **Idli and Chai:** start a burn workload and **leave it running** for this whole lab.

    {{BURN_TS}}

    **Vada:** start a memory hog of 12 GiB:

    {{MEMHOG_TS:12}}

    **Dosa:** nothing to start. Go straight to the next step.

    !!! see "You should see"
        `pod/burn created` or `pod/memhog created`.

<!-- only:gke -->
!!! step "Open Metrics Explorer"
    Run this to print the link, then open it:

    ```bash
    echo "https://console.cloud.google.com/monitoring/metrics-explorer?project=${WORKSHOP_PROJECT}"
    ```

    !!! see "You should see"
        The Google Cloud console with **Metrics Explorer** open, in the workshop project.

    !!! tip "Wrong project?"
        Check the project picker at the top of the console says the workshop project. The link above sets it for you.

!!! step "Switch the query editor to PromQL"
    In the query panel, find the **Builder / Code** (or **PromQL**) toggle at the top right and choose **PromQL**.

    !!! why "Why this matters"
        PromQL is a short text language for asking about metrics. Pasting a query is easier than clicking through menus.

!!! step "Build your table's query"
    This prints a query with **your** node names filled in:

    ```bash
    NODES=$(kubectl get nodes -l workshop.devfest/table=$TABLE -o jsonpath='{.items[*].metadata.name}' | tr ' ' '|')
    echo "kubernetes_io:node_accelerator_duty_cycle{monitored_resource=\"k8s_node\",cluster_name=\"$CLUSTER\",node_name=~\"$NODES\"}"
    ```

    Copy the printed line (it starts with `kubernetes_io:`), paste it into the PromQL box, and click **Run query**.

    !!! see "You should see"
        A line chart. Your table's **time-sharing** node climbs towards **100%**. The MPS node stays near 0 (nobody's used it yet).

!!! step "Now look at memory"
    In the query box, change `duty_cycle` to `memory_used` and run it again.

    !!! see "You should see"
        Your time-sharing node at roughly **12 GiB** (about 13,000,000,000 bytes), which is Vada's memory hog.

!!! step "Try to find out *which team* is using the GPU"
    In the query box, try:

    ```text
    kubernetes_io:container_accelerator_duty_cycle
    ```

    !!! see "You should see"
        **No data** for your pods.

    !!! why "The gotcha"
        On a normal, unshared GPU, GKE reports metrics **per container**. On **time-sharing and MPS** nodes those per-container metrics
        **aren't collected**: you only get one number for the whole GPU. Cloud Monitoring can say *"the GPU is 100% busy"*, but not **who** is using it.
        (On **MIG** nodes, `duty_cycle` isn't available at all.)

<!-- /only -->
<!-- only:jarvislabs -->
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

<!-- /only -->

!!! step extra "Watch from the terminal instead"
    ```bash
    bash scripts/attendee/watch-gpu.sh
    ```

    It prints your table's duty cycle and memory every 30 seconds, using the same query through the API. ++ctrl+c++ to stop.

!!! step "Everyone · Clean up"
    ```bash
    kubectl delete pod --all
    ```

    !!! see "You should see"
        Your pods deleted.

<!-- only:gke -->
!!! tip "Look up at the projector"
    The big screen shows **every** table's GPU on one dashboard. Can you spot yours? Which table is running hottest?
<!-- /only -->

## Test your knowledge

<div class="quiz" data-answer="b">
  <p class="q">Your shared GPU node shows 100% duty cycle. What can Cloud Monitoring tell you about it?</p>
  <button data-opt="a">Which team's pod is using most of it</button>
  <button data-opt="b">Only that the GPU as a whole is busy</button>
  <button data-opt="c">Nothing. Shared GPUs have no metrics</button>
  <div class="explain">Shared GPU nodes report <b>node-level</b> metrics only. To know who's using it, you need metrics from the workloads themselves (vLLM, for example, exports its own).</div>
</div>

<!-- only:gke -->
!!! takeaway "Key takeaway"
    - Shared-GPU nodes report `duty_cycle`, `memory_used` and `memory_total` **per node**.
    - They answer *"is this GPU overloaded or idle?"*, not *"who's using it?"*.
    - Allow 1–3 minutes of lag.

<!-- /only -->
<!-- only:jarvislabs -->
!!! takeaway "Key takeaway"
    - DCGM reports GPU busy % and memory **per GPU**, not per pod.
    - It answers *"is this GPU overloaded or idle?"*, not *"who's using it?"*.
    - For per-team answers you need metrics from the workloads themselves.

<!-- /only -->

!!! checkpoint "Checkpoint"
    You found your table's GPU and saw it was busy, but not who was using it. **Next: [Step 6 · MPS](04-mps.md).**
