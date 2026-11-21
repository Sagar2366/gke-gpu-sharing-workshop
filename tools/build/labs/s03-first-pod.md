!!! abstract "What you'll do"
    Pick your team, connect to the cluster, and run your first pod on your table's GPU.

!!! step "Pick your team"
    Look at your **table card** for your table id (e.g. `t07`). Agree who plays `dosa`, `idli`, `vada` and `chai`.

    ??? tip "Fewer than four people?"
        Fine. Someone plays two teams: open a second Cloud Shell tab (**+**) and run the next task again with the other team name.

!!! step "Connect as your team"
    Use **your** table and team:

    ```bash
    source scripts/attendee/setup.sh t07 dosa
    ```

    !!! see "You should see"
        A banner with your `table`, `team` and `namespace` (e.g. `t07-dosa`).

    ??? failure "Couldn't download the kubeconfig"
        Check the table/team spelling. If it's right, the cluster may not be ready yet: wait for the instructor's **go**.

!!! step "Run your first GPU pod"
    This pod asks for **one GPU** on your table's machine and prints what it sees:

    ```bash
    kubectl apply -f - <<EOF
    apiVersion: v1
    kind: Pod
    metadata:
      name: probe
    spec:
      restartPolicy: Never
      nodeSelector:
        workshop.devfest/gpu-mode: exclusive
        workshop.devfest/table: ${TABLE}
      containers:
      - name: probe
        image: ${IMAGE}
        command: ["bash", "-c", "nvidia-smi -L; python3 /scripts/probe.py"]
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
        GPU 0: NVIDIA L4 (UUID: GPU-3b1f6c2e-...)
        device                  : NVIDIA L4
        SMs visible             : 58
        GPU memory free / total : 21.8 GiB / 22.0 GiB
        ```

    ??? question "What's in that YAML?"
        `nodeSelector` = *"only on my table's GPU"* · `nvidia.com/gpu: 1` = *"I need one GPU"* · `image` = a container with PyTorch and vLLM ·
        `command` = run `probe.py`, a tiny script that reports what the GPU looks like from inside.

!!! step "Clean up"
    ```bash
    kubectl delete pod probe
    ```

    !!! tip "The four commands you'll use all day"
        `kubectl apply` (create) · `kubectl get pods` (status) · `kubectl logs` (output) · `kubectl delete` (remove)
