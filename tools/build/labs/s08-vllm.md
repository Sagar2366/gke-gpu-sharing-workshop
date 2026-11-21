!!! abstract "What you'll do"
    Run a real AI model, **Gemma 3 1B**, with **vLLM**, a popular model server. Each team gets its own copy on the **same L4**.

!!! problem "The classic problem (without limits)"
    vLLM grabs **90% of the GPU's memory** when it starts, on purpose, to answer fast. On a time-sliced GPU, the first server takes
    ~20 GB and **everyone else's crashes** (`Free memory on device ... is less than desired GPU memory utilization`).
    You'd have to hand-tune a memory setting on every server.

!!! step "Everyone · Save the Gemma helper"
    This **only saves** a script. Copy the whole box:

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
            workshop.devfest/gpu-mode: hami
            workshop.devfest/table: ${TABLE}
          containers:
          - name: vllm
            image: ${IMAGE}
            command: ["python3", "-m", "vllm.entrypoints.openai.api_server"]
            args:
            - --model=${MODEL}
            - --max-model-len=2048
            - --max-num-seqs=8
            - --enforce-eager
            - --port=8000
            env:
            - {name: HF_HUB_CACHE, value: /models}
            - {name: HF_HUB_OFFLINE, value: "1"}
            ports: [{containerPort: 8000}]
            readinessProbe:
              httpGet: {path: /health, port: 8000}
              periodSeconds: 5
              failureThreshold: 60
            resources:
              requests: {cpu: 1500m, memory: 6Gi}
              limits: {memory: 10Gi, nvidia.com/gpu: 1, nvidia.com/gpumem: ${GPU_MEM:-5000}, nvidia.com/gpucores: ${GPU_CORES:-25}}
            volumeMounts:
            - {name: models, mountPath: /models, readOnly: true}
          volumes:
          - name: models
            hostPath: {path: /var/lib/workshop/hf, type: Directory}
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
    echo saved
    ```

    ??? question "What's special here?"
        No vLLM memory setting at all, so it uses its **default 90%**. But HAMi gives it a **5 GB GPU**, so 90% means ~4.5 GB.

!!! step "Everyone · Deploy your Gemma"
    ```bash
    bash /tmp/gemma.sh
    kubectl rollout status deploy/gemma --timeout=5m
    ```

    !!! see "You should see"
        `deployment "gemma" successfully rolled out` for **all four** teams. No crashes.

!!! solution "Fixed by the limit"
    Four model servers on one L4, each believing it has its own 5 GB GPU. No hand-tuning.

!!! step "Everyone · Talk to your model"
    ```bash
    kubectl port-forward svc/gemma 8000:8000 >/dev/null 2>&1 &
    sleep 3
    curl -s http://127.0.0.1:8000/v1/chat/completions -H 'Content-Type: application/json' -d "{
      \"model\": \"${MODEL}\", \"max_tokens\": 100,
      \"messages\": [{\"role\": \"user\", \"content\": \"Three tips for surviving Silk Board junction traffic?\"}]}" \
      | jq -r '.choices[0].message.content'
    ```

    !!! see "You should see"
        Three (probably funny) tips from Gemma.

!!! step "Everyone · Time it"
    ```bash
    bash scripts/attendee/bench.sh 5
    ```

    !!! see "You should see"
        Five timings and an average. Each team gets steady answers, because each server has its own compute share.

!!! step "Everyone · Clean up"
    ```bash
    kill %1 2>/dev/null; kubectl delete deploy,svc,pod --all
    ```
