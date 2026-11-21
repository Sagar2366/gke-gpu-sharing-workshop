!!! abstract "What you'll do"
    All four teams try to use the table's GPU at the same time. Watch what Kubernetes does by default.

!!! step ":material-food: Dosa · Start a notebook-style pod"
    **Dosa only.** This pod grabs the GPU and then just sits there, like an open notebook nobody is typing in:

    ```bash
    kubectl apply -f - <<EOF
    apiVersion: v1
    kind: Pod
    metadata:
      name: hold
      labels: {app: hold}
    spec:
      nodeSelector:
        workshop.devfest/gpu-mode: exclusive
        workshop.devfest/table: ${TABLE}
      containers:
      - name: hold
        image: ${IMAGE}
        command: ["sleep", "infinity"]
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
    kubectl get pods
    ```

    !!! see "You should see"
        `hold   1/1   Running`

!!! step ":material-rice: Idli, :material-cookie: Vada, :material-tea: Chai · Try to start yours"
    **The other three** run the same command:

    ```bash
    kubectl apply -f - <<EOF
    apiVersion: v1
    kind: Pod
    metadata:
      name: hold
      labels: {app: hold}
    spec:
      nodeSelector:
        workshop.devfest/gpu-mode: exclusive
        workshop.devfest/table: ${TABLE}
      containers:
      - name: hold
        image: ${IMAGE}
        command: ["sleep", "infinity"]
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
    sleep 10; kubectl get pods
    ```

    !!! see "You should see"
        `hold   0/1   Pending`. It never starts.

!!! step "Everyone · Ask Kubernetes why"
    ```bash
    kubectl describe pod hold | tail -3
    ```

    !!! see "You should see (Idli, Vada, Chai)"
        `... 0/N nodes are available: ... Insufficient nvidia.com/gpu ...`

!!! step ":material-food: Dosa · Check how busy the GPU really is"
    ```bash
    kubectl exec hold -- nvidia-smi --query-gpu=utilization.gpu,memory.used --format=csv
    ```

    !!! see "You should see"
        Around `0 %` busy and almost no memory used.

!!! problem "Problem · One pod, one whole GPU"
    By default Kubernetes hands out GPUs **whole**: Dosa's idle pod holds the entire L4 and three teams wait.
    On a cluster of expensive GPUs, that's a lot of money doing nothing.

!!! step "Everyone · Clean up"
    ```bash
    kubectl delete pod hold
    ```

    Then wait: the instructor switches every table GPU to **time-sharing** (on the big screen, ~1 minute).

!!! screen "On the big screen · Turn on time-slicing"
    ```bash
    ./scripts/jarvislabs/04-switch-strategy.sh ts
    ```

    One label per node changes the device plugin's config: each L4 now advertises **4** GPUs instead of 1.
