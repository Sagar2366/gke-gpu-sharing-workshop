# Step 8 · Gemma on a shared GPU with vLLM

<div class="lesson-head" markdown>
<span class="pill">Module 2 · Step 8 of 7</span>
<span class="pill time">:material-timer-outline: 15 min</span>
<span class="pill who">:material-account-group: whole table, in order</span>
[Skip to the Finale :material-arrow-right:](06b-finale.md){ .skip }
</div>

!!! abstract "What you'll do"
    Run a real AI chatbot, **[Gemma 3 1B](https://huggingface.co/google/gemma-3-1b-it)** (an open model from Google),
    with **[vLLM](https://docs.vllm.ai)**, a popular model server. Find out why your teammate's copy crashes, fix it with
    **one setting**, and measure how a noisy neighbour affects chat response time.

!!! info "No Hugging Face account needed today"
    Gemma normally needs a Hugging Face login. The organisers already downloaded it onto every GPU machine, so your
    pod loads it from local disk in seconds.

## Part A · Get ready

!!! step "Everyone · Save the Gemma helper"
    This **only saves** a small script (it doesn't start anything yet). Copy the whole box and paste it in one go:

    ```bash
    cat > /tmp/gemma.sh <<'OUTER'
    kubectl apply -f - <<EOF
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: gemma
    spec:
      replicas: 1
      strategy: {type: Recreate}
      selector: {matchLabels: {app: gemma}}
      template:
        metadata:
          labels: {app: gemma, team: ${TEAM}}
        spec:
          nodeSelector:
            cloud.google.com/gke-gpu-sharing-strategy: time-sharing
            cloud.google.com/gke-max-shared-clients-per-gpu: "4"
            workshop.devfest/table: ${TABLE}
          containers:
          - name: vllm
            image: ${IMAGE}
            command: ["python3", "-m", "vllm.entrypoints.openai.api_server"]
            args:
            - --model=${MODEL}
            - --gpu-memory-utilization=${GPU_UTIL:-0.9}   # 0.9 is vLLM's default
            - --max-model-len=4096
            - --max-num-seqs=16
            - --enforce-eager
            - --port=8000
            env:
            - {name: LD_LIBRARY_PATH, value: /usr/local/nvidia/lib64}
            - {name: HF_HUB_CACHE, value: /models}
            - {name: HF_HUB_OFFLINE, value: "1"}
            ports: [{containerPort: 8000}]
            readinessProbe:
              httpGet: {path: /health, port: 8000}
              periodSeconds: 5
              failureThreshold: 60
            resources:
              requests: {cpu: 1500m, memory: 6Gi}
              limits: {memory: 10Gi, nvidia.com/gpu: 1}
            volumeMounts:
            - {name: models, mountPath: /models, readOnly: true}
            - {name: dshm, mountPath: /dev/shm}
          volumes:
          - name: models
            hostPath: {path: /var/lib/workshop/hf, type: Directory}
          - name: dshm
            emptyDir: {medium: Memory, sizeLimit: 1Gi}
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: gemma
    spec:
      selector: {app: gemma}
      ports: [{port: 8000, targetPort: 8000}]
    EOF
    OUTER
    echo "saved"
    ```

    !!! see "You should see"
        ```text
        saved
        ```

    ??? question "What's in it?"
        - A **Deployment** called `gemma`: keeps one vLLM server pod running.
        - A **Service** called `gemma`: a stable address for it on port 8000.
        - The key setting is **`--gpu-memory-utilization`**: *what fraction of the GPU's memory vLLM may take.* This lab is about that one line.
        - `bash /tmp/gemma.sh` deploys it with the default (0.9); `GPU_UTIL=0.2 bash /tmp/gemma.sh` deploys it with 20%.

## Part B · The gotcha

!!! step ":material-food: Dosa · Deploy Gemma with default settings"
    **Dosa only.**

    ```bash
    bash /tmp/gemma.sh
    kubectl rollout status deploy/gemma --timeout=5m
    ```

    !!! see "You should see"
        After a minute or two:

        ```text
        deployment "gemma" successfully rolled out
        ```

!!! step ":material-food: Dosa · How much memory did it take?"
    ```bash
    kubectl exec deploy/gemma -- /usr/local/nvidia/bin/nvidia-smi --query-gpu=memory.used,memory.total --format=csv
    ```

    !!! see "You should see"
        Roughly **20,000 MiB** used, for a model whose weights are only about **2 GB**.

    !!! why "Why this matters"
        By default vLLM grabs **90% of the GPU's memory** at startup, on purpose: it reserves space (the *KV cache*) to answer many requests fast.
        That's great on a GPU of your own, and a problem on a shared one.

!!! step ":material-cookie: Vada · Try to deploy your own Gemma"
    **Vada only.**

    ```bash
    bash /tmp/gemma.sh
    sleep 60; kubectl get pods
    kubectl logs deploy/gemma | grep -i -E "error|memory" | tail -3
    ```

    !!! see "You should see"
        ```text
        gemma-6d9c…   0/1   CrashLoopBackOff
        ValueError: Free memory on device (1.9/22.0 GiB) on startup is less than desired GPU memory utilization (0.9, 19.8 GiB)...
        ```

        (The exact wording depends on the vLLM version.)

    !!! why "The gotcha"
        Kubernetes happily put Vada's pod on the GPU: there was a free **chair**. Nothing checked **memory**.
        Servers that **reserve memory up front** (vLLM, TGI, TensorFlow…) assume they're alone on the GPU.

## Part C · Fix it

!!! step ":material-food: Dosa · Redeploy using 20% of the GPU"
    **Dosa first.** This frees the memory Dosa was holding:

    ```bash
    GPU_UTIL=0.2 bash /tmp/gemma.sh
    kubectl rollout status deploy/gemma --timeout=5m
    ```

    !!! see "You should see"
        `successfully rolled out`.

    !!! why "Why 0.2?"
        Four servers on one L4 means about a quarter of memory each, minus some headroom: **20%**.

!!! step ":material-cookie: Vada, :material-rice: Idli, :material-tea: Chai · Deploy at 20%"
    **Only after Dosa is ready**, the other three run:

    ```bash
    GPU_UTIL=0.2 bash /tmp/gemma.sh
    kubectl rollout status deploy/gemma --timeout=5m
    ```

    !!! see "You should see"
        `successfully rolled out` for everyone.

    !!! tip "Vada still crashing?"
        Kubernetes waits longer between each restart. Restart it right away with `kubectl delete pod -l app=gemma`.

!!! step "Everyone · Four chatbots, one GPU"
    ```bash
    kubectl exec deploy/gemma -- /usr/local/nvidia/bin/nvidia-smi --query-gpu=memory.used,memory.total --format=csv
    ```

    !!! see "You should see"
        Around **18,000 MiB** used in total: four Gemma servers sharing one L4.

## Part D · Chat with it and time it

!!! step "Everyone · Connect to your Gemma"
    ```bash
    kubectl port-forward svc/gemma 8000:8000 >/dev/null 2>&1 &
    sleep 3
    ```

    !!! why "What did that do?"
        It connects port 8000 in **your Cloud Shell** to **your Gemma server**, so `http://127.0.0.1:8000` reaches it.
        The `&` runs it in the background. Stop it later with `kill %1`.

!!! step "Everyone · Ask Gemma something"
    ```bash
    curl -s http://127.0.0.1:8000/v1/chat/completions -H 'Content-Type: application/json' -d "{
      \"model\": \"${MODEL}\",
      \"max_tokens\": 120,
      \"messages\": [{\"role\": \"user\", \"content\": \"Give me three tips for surviving Silk Board junction traffic.\"}]
    }" | jq -r '.choices[0].message.content'
    ```

    !!! see "You should see"
        Three (probably funny) tips from Gemma.

!!! step "Everyone · Measure response time"
    ```bash
    bash scripts/attendee/bench.sh 5
    ```

    !!! see "You should see"
        Five timings and an average, e.g. `average  1.10 s`. **Write Dosa's average on the card** as *"quiet GPU"*.

!!! step ":material-rice: Idli + :material-tea: Chai · Become noisy neighbours"
    **Idli and Chai:** stop serving and start the greedy workload instead:

    ```bash
    kill %1 2>/dev/null; kubectl delete deploy gemma
    ```

    ```bash
    kubectl apply -f - <<EOF
    apiVersion: v1
    kind: Pod
    metadata:
      name: burn
      labels: {app: burn, team: ${TEAM}}
    spec:
      nodeSelector:
        cloud.google.com/gke-gpu-sharing-strategy: time-sharing
        cloud.google.com/gke-max-shared-clients-per-gpu: "4"
        workshop.devfest/table: ${TABLE}
      containers:
      - name: burn
        image: ${IMAGE}
        command: ["bash", "-c", "/usr/local/nvidia/bin/nvidia-smi -L; exec python3 /scripts/burn.py"]
        env:
        - {name: LD_LIBRARY_PATH, value: /usr/local/nvidia/lib64}
        - {name: DUTY, value: "${DUTY:-1.0}"}
        resources:
          requests: {cpu: 500m, memory: 2Gi}
          limits: {nvidia.com/gpu: 1}
        volumeMounts: [{name: scripts, mountPath: /scripts}]
      volumes:
      - name: scripts
        configMap: {name: gpu-scripts}
    EOF
    ```

!!! step ":material-food: Dosa + :material-cookie: Vada · Measure again"
    ```bash
    bash scripts/attendee/bench.sh 5
    ```

    !!! see "You should see"
        A **higher** average, often 2× or more. Write it as *"with burn"*.

    !!! why "Why this matters"
        With time-sharing, every step of Gemma's answer **waits its turn** behind Idli's and Chai's maths.

!!! question "Talk at your table (2 minutes)"
    You run the platform. Dosa must answer chats quickly; Idli's batch job just has to finish overnight.
    Which strategy would you give each of them? Keep your answer for [Step 10](07-decision-guide.md).

!!! step "Everyone · Clean up"
    ```bash
    kill %1 2>/dev/null; kubectl delete deploy,svc,pod --all
    ```

??? step extra "Gemma on a MIG slice (if you finish early)"
    Hardware isolation for the team that needs fast answers:

    ```bash
    sed -e 's/gke-gpu-sharing-strategy: time-sharing/gke-gpu-partition-size: ${MIG_PARTITION}/' \
        -e '/gke-max-shared-clients-per-gpu/d' -e '/workshop.devfest\/table/d' \
        -e 's/max-model-len=4096/max-model-len=2048/' /tmp/gemma.sh > /tmp/gemma-mig.sh
    GPU_UTIL=0.85 bash /tmp/gemma-mig.sh
    kubectl rollout status deploy/gemma --timeout=5m
    kubectl port-forward svc/gemma 8000:8000 >/dev/null 2>&1 &
    sleep 3; bash scripts/attendee/bench.sh 5
    ```

    Slower than a quiet L4 (a slice is 1/7 of an A100), but it **doesn't change** when neighbours get busy.
    Clean up afterwards: `kill %1; kubectl delete deploy,svc --all`

??? step extra "Gemma on MPS (if you finish early)"
    ```bash
    sed -e 's/gke-gpu-sharing-strategy: time-sharing/gke-gpu-sharing-strategy: mps/' \
        -e 's/^    spec:$/    spec:\n      hostIPC: true/' /tmp/gemma.sh > /tmp/gemma-mps.sh
    GPU_UTIL=0.2 bash /tmp/gemma-mps.sh
    ```

    MPS caps this pod at about 5.5 GiB, so `0.2` (≈4.4 GiB) fits but `0.9` fails, and this time **MPS** refuses, not a neighbour.
    Clean up afterwards: `kubectl delete deploy,svc --all`

## Test your knowledge

<div class="quiz" data-answer="b">
  <p class="q">Four vLLM servers need to share one L4. What do you change?</p>
  <button data-opt="a">Nothing. Kubernetes will divide the memory</button>
  <button data-opt="b">Set <code>--gpu-memory-utilization</code> to about 0.2 on every server</button>
  <button data-opt="c">Request <code>nvidia.com/gpu: 0.25</code></button>
  <div class="explain">Kubernetes doesn't divide GPU memory, and GPU requests must be whole numbers. Each server has to be told its own memory budget.</div>
</div>

!!! takeaway "Key takeaway"
    - Model servers like vLLM **reserve ~90% of GPU memory** by default. On a shared GPU, set `--gpu-memory-utilization`.
    - **Every** co-tenant needs a budget, and they must add up to less than the GPU.
    - For chat services with speed promises, isolate them: **MIG** (hard) or **MPS** (soft).

!!! checkpoint "Checkpoint"
    You chatted with your own Gemma, saw the 90% default crash a teammate, and measured the noisy-neighbour slowdown.
    **Now watch the big screen for the [Finale](06b-finale.md)**, then [Step 10](07-decision-guide.md).
