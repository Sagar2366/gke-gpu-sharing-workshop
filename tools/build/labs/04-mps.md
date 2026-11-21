# Step 6 · NVIDIA MPS

<div class="lesson-head" markdown>
<span class="pill">Module 2 · Step 6 of 7</span>
<span class="pill time">:material-timer-outline: 15 min</span>
<span class="pill who">:material-account-group: whole table, in order</span>
[Skip to Step 7 :material-arrow-right:](05-mig.md){ .skip }
</div>

!!! abstract "What you'll do"
    The same experiment as Step 4, on a GPU set up with **NVIDIA MPS**. This time each of you gets a fixed
    **quarter** of the GPU. You'll see your speed stop depending on your neighbours, then find out how firm that quarter really is.

**MPS** is the **shared cab with assigned seats**: programs run **at the same time**, each capped at about **¼ of the cores and memory**.

??? planb "On the Plan B (Jarvislabs) cluster?"
    The organisers have just **switched your table's GPU to MPS** (same node, new setting). The labs work as written, but MPS here is
    NVIDIA's device-plugin version, not GKE's, so:

    - The *"forget hostIPC"* step **may just work**: NVIDIA's plugin sets up the connection to the MPS daemon itself.
    - `probe.py` may show **no `CUDA_MPS_*` variables** even though SMs and memory are capped. The plugin's MPS daemon applies the limits.
    - The *"change your own limit"* step may behave differently. **Note what happens.** It's a good discussion point.

## Part A · Meet MPS

!!! step "Everyone · Try MPS the wrong way first"
    Run this probe **without** the special `hostIPC` setting MPS needs:

    ```bash
    kubectl apply -f - <<EOF
    apiVersion: v1
    kind: Pod
    metadata:
      name: probe-noipc
    spec:
      restartPolicy: Never
      activeDeadlineSeconds: 90
      nodeSelector:
        cloud.google.com/gke-gpu-sharing-strategy: mps
        workshop.devfest/table: ${TABLE}
      containers:
      - name: probe
        image: ${IMAGE}
        command: ["python3", "/scripts/probe.py"]
        env:
        - {name: LD_LIBRARY_PATH, value: /usr/local/nvidia/lib64}
        resources:
          limits: {nvidia.com/gpu: 1}
        volumeMounts: [{name: scripts, mountPath: /scripts}]
      volumes:
      - name: scripts
        configMap: {name: gpu-scripts}
    EOF
    ```

    Then wait and look:

    ```bash
    sleep 45; kubectl logs probe-noipc; kubectl get pod probe-noipc
    ```

    !!! see "You should see"
        Either a message that it **can't reach a GPU**, or a pod still stuck that is killed after 90 seconds.

    !!! why "The gotcha"
        MPS programs talk to an **MPS control program** on the node through shared memory. Without `hostIPC: true`, they can't reach it.
        **Every MPS pod needs `hostIPC: true`.**

        `hostIPC` lets the pod share the node's inter-process communication, which is a security trade-off. Use MPS only between teams that trust each other.

!!! step "Everyone · Clean up the broken probe"
    ```bash
    kubectl delete pod probe-noipc
    ```

!!! step "Everyone · Now the right way"
    Same probe, with `hostIPC: true`:

    ```bash
    kubectl apply -f - <<EOF
    apiVersion: v1
    kind: Pod
    metadata:
      name: probe
    spec:
      restartPolicy: Never
      hostIPC: true
      nodeSelector:
        cloud.google.com/gke-gpu-sharing-strategy: mps
        workshop.devfest/table: ${TABLE}
      containers:
      - name: probe
        image: ${IMAGE}
        command: ["python3", "/scripts/probe.py"]
        env:
        - {name: LD_LIBRARY_PATH, value: /usr/local/nvidia/lib64}
        resources:
          limits: {nvidia.com/gpu: 1}
        volumeMounts: [{name: scripts, mountPath: /scripts}]
      volumes:
      - name: scripts
        configMap: {name: gpu-scripts}
    EOF
    ```

    ```bash
    sleep 20; kubectl logs probe
    ```

    !!! see "You should see"
        ```text
        CUDA_MPS_ACTIVE_THREAD_PERCENTAGE: 25
        CUDA_MPS_PINNED_DEVICE_MEM_LIMIT: 0=5622M
        device                  : NVIDIA L4
        SMs visible             : 14
        GPU memory free / total : 5.3 GiB / 22.0 GiB
        ```

    !!! why "Compare with Step 3"
        | | Step 3 (time-sharing) | Now (MPS) |
        |---|---|---|
        | SMs you can use | 58 | **~14** |
        | Memory you can use | ~22 GiB | **~5.5 GiB** |

        Each person now sees about **a quarter** of the GPU, and nobody changed their code.

!!! step "Everyone · Clean up"
    ```bash
    kubectl delete pod probe
    ```

## Part B · The noisy neighbour, again

!!! step ":material-food: Dosa · Start the workload alone"
    **Dosa only.**

    ```bash
    kubectl apply -f - <<EOF
    apiVersion: v1
    kind: Pod
    metadata:
      name: burn
      labels: {app: burn, team: ${TEAM}}
    spec:
      hostIPC: true
      nodeSelector:
        cloud.google.com/gke-gpu-sharing-strategy: mps
        workshop.devfest/table: ${TABLE}
      containers:
      - name: burn
        image: ${IMAGE}
        command: ["python3", "/scripts/burn.py"]
        env:
        - {name: LD_LIBRARY_PATH, value: /usr/local/nvidia/lib64}
        resources:
          requests: {cpu: 500m, memory: 2Gi}
          limits: {nvidia.com/gpu: 1}
        volumeMounts: [{name: scripts, mountPath: /scripts}]
      volumes:
      - name: scripts
        configMap: {name: gpu-scripts}
    EOF
    ```

    ```bash
    kubectl logs -f burn
    ```

    !!! see "You should see"
        TFLOPS lines every 5 seconds, **lower** than Dosa's Step 4 baseline. Write it on the card as *"MPS alone"*.

    !!! why "Why this matters"
        Dosa is capped at ~25% of the cores **even with the GPU to itself**. That's the price of a guaranteed seat.

!!! step ":material-rice: Idli, :material-cookie: Vada, :material-tea: Chai · Join in"
    **Idli first, then Vada and Chai**, each runs the same command while Dosa watches:

    ```bash
    kubectl apply -f - <<EOF
    apiVersion: v1
    kind: Pod
    metadata:
      name: burn
      labels: {app: burn, team: ${TEAM}}
    spec:
      hostIPC: true
      nodeSelector:
        cloud.google.com/gke-gpu-sharing-strategy: mps
        workshop.devfest/table: ${TABLE}
      containers:
      - name: burn
        image: ${IMAGE}
        command: ["python3", "/scripts/burn.py"]
        env:
        - {name: LD_LIBRARY_PATH, value: /usr/local/nvidia/lib64}
        resources:
          requests: {cpu: 500m, memory: 2Gi}
          limits: {nvidia.com/gpu: 1}
        volumeMounts: [{name: scripts, mountPath: /scripts}]
      volumes:
      - name: scripts
        configMap: {name: gpu-scripts}
    EOF
    ```

    !!! see "Dosa should see"
        The number stays **about the same**. Write it as *"MPS with 3 neighbours"*.

    !!! why "Why this matters"
        | | Time-sharing (Step 4) | MPS (now) |
        |---|---|---|
        | Dosa alone | high | lower (capped) |
        | Dosa + 3 neighbours | **~¼ of alone** | **~same as alone** |

        With MPS, Dosa's speed is **predictable**. It isn't perfectly flat, because memory bandwidth and caches are still shared.

!!! step "Idli, Vada, Chai · Stop your workloads"
    **Everyone except Dosa:**

    ```bash
    kubectl delete pod burn
    ```

## Part C · Memory caps, and how firm they are

!!! step ":material-rice: Idli · Try to grab 20 GiB again"
    **Idli only.**

    ```bash
    kubectl apply -f - <<EOF
    apiVersion: v1
    kind: Pod
    metadata:
      name: memhog
    spec:
      hostIPC: true
      nodeSelector:
        cloud.google.com/gke-gpu-sharing-strategy: mps
        workshop.devfest/table: ${TABLE}
      containers:
      - name: memhog
        image: ${IMAGE}
        command: ["python3", "/scripts/memhog.py"]
        env:
        - {name: LD_LIBRARY_PATH, value: /usr/local/nvidia/lib64}
        - {name: GIB, value: "20"}
        resources:
          limits: {nvidia.com/gpu: 1}
        volumeMounts: [{name: scripts, mountPath: /scripts}]
      volumes:
      - name: scripts
        configMap: {name: gpu-scripts}
    EOF
    ```

    ```bash
    kubectl logs -f memhog
    ```

    !!! see "You should see"
        ```text
        [memhog] holding  5 GiB | device free   0.3 of  22.0 GiB
        [memhog] OUT OF MEMORY after 5 GiB: CUDA out of memory...
        ```

    !!! why "Why this matters"
        This time the greedy program hits **its own** limit, around 5 GiB. Compare that with Step 4, where it took 20 GiB and crashed Chai.

!!! step ":material-tea: Chai · Ask for 4 GiB"
    **Chai only.**

    ```bash
    kubectl apply -f - <<EOF
    apiVersion: v1
    kind: Pod
    metadata:
      name: memhog
    spec:
      hostIPC: true
      nodeSelector:
        cloud.google.com/gke-gpu-sharing-strategy: mps
        workshop.devfest/table: ${TABLE}
      containers:
      - name: memhog
        image: ${IMAGE}
        command: ["python3", "/scripts/memhog.py"]
        env:
        - {name: LD_LIBRARY_PATH, value: /usr/local/nvidia/lib64}
        - {name: GIB, value: "4"}
        resources:
          limits: {nvidia.com/gpu: 1}
        volumeMounts: [{name: scripts, mountPath: /scripts}]
      volumes:
      - name: scripts
        configMap: {name: gpu-scripts}
    EOF
    ```

    ```bash
    sleep 20; kubectl logs memhog
    ```

    !!! see "You should see"
        `holding 4 GiB` and `done`. **It works this time**, because Idli couldn't take Chai's share.

!!! step ":material-rice: Idli · Change your own limit"
    **Idli only.** Delete the memory hog and try again, this time **setting the MPS limits yourself** to 16 GiB and 100% of cores:

    ```bash
    kubectl delete pod memhog
    ```

    ```bash
    kubectl apply -f - <<EOF
    apiVersion: v1
    kind: Pod
    metadata:
      name: memhog
    spec:
      hostIPC: true
      nodeSelector:
        cloud.google.com/gke-gpu-sharing-strategy: mps
        workshop.devfest/table: ${TABLE}
      containers:
      - name: memhog
        image: ${IMAGE}
        command: ["python3", "/scripts/memhog.py"]
        env:
        - {name: LD_LIBRARY_PATH, value: /usr/local/nvidia/lib64}
        - {name: GIB, value: "14"}
        - {name: CUDA_MPS_PINNED_DEVICE_MEM_LIMIT, value: "0=16G"}
        - {name: CUDA_MPS_ACTIVE_THREAD_PERCENTAGE, value: "100"}
        resources:
          limits: {nvidia.com/gpu: 1}
        volumeMounts: [{name: scripts, mountPath: /scripts}]
      volumes:
      - name: scripts
        configMap: {name: gpu-scripts}
    EOF
    ```

    ```bash
    kubectl logs -f memhog
    ```

    !!! see "You should see"
        How far does it get? Compare with the ~5 GiB wall from before.

    !!! why "The gotcha"
        The MPS limits are **just environment variables in the pod**. The GKE documentation shows pods raising and lowering them.
        That's handy for giving a big workload more room, and a problem if you thought they were a security wall.
        To enforce them, an admin must **block pods that set `CUDA_MPS_*`** (for example with an admission policy).

!!! step "Everyone · Clean up"
    ```bash
    kubectl delete pod --all
    ```

!!! step extra ":material-tea: Chai · Two seats are allowed here"
    In Step 4, asking for 2 GPUs was rejected. On an MPS node with **one** physical GPU, GKE allows it and gives you two shares:

    ```bash
    kubectl apply -f - <<EOF
    apiVersion: v1
    kind: Pod
    metadata:
      name: probe2
    spec:
      restartPolicy: Never
      hostIPC: true
      nodeSelector:
        cloud.google.com/gke-gpu-sharing-strategy: mps
        workshop.devfest/table: ${TABLE}
      containers:
      - name: probe2
        image: ${IMAGE}
        command: ["python3", "/scripts/probe.py"]
        env:
        - {name: LD_LIBRARY_PATH, value: /usr/local/nvidia/lib64}
        resources:
          limits: {nvidia.com/gpu: 2}
        volumeMounts: [{name: scripts, mountPath: /scripts}]
      volumes:
      - name: scripts
        configMap: {name: gpu-scripts}
    EOF
    ```

    ```bash
    sleep 20; kubectl logs probe2 | grep -E "THREAD|MEM_LIMIT|SMs|free"
    kubectl delete pod probe2
    ```

    You should see about **50%** of threads and ~11 GiB.

## Test your knowledge

<div class="quiz" data-answer="c">
  <p class="q">Which line must every MPS pod include?</p>
  <button data-opt="a"><code>restartPolicy: Never</code></button>
  <button data-opt="b"><code>nvidia.com/gpu: 4</code></button>
  <button data-opt="c"><code>hostIPC: true</code></button>
  <div class="explain">MPS programs reach the MPS control program through the node's shared memory, which needs <code>hostIPC: true</code>.</div>
</div>

<div class="quiz" data-answer="a">
  <p class="q">Under MPS, Dosa's speed with 3 noisy neighbours was…</p>
  <button data-opt="a">About the same as alone</button>
  <button data-opt="b">About a quarter of alone</button>
  <button data-opt="c">Zero</button>
  <div class="explain">Each MPS client is capped at its own share of the cores, so neighbours can't take Dosa's. Shared memory bandwidth can still cause a small dip.</div>
</div>

!!! takeaway "Key takeaway: MPS"
    - **Protects:** a fixed share of cores and memory per pod, so speed is predictable.
    - **Doesn't protect:** memory bandwidth and caches; crashes are less contained; **pods can change their own limits**.
    - **Requires:** `hostIPC: true` on every pod.
    - **Great for:** many small, steady inference or batch jobs from one trusted team.

!!! checkpoint "Checkpoint"
    Your probe showed `CUDA_MPS_ACTIVE_THREAD_PERCENTAGE: 25`, Dosa's speed held steady, and Idli hit a memory wall.
    **Next: [Step 7 · MIG](05-mig.md).**
