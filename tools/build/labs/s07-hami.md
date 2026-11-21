!!! solution "Fix · HAMi: ask for memory and compute, and get exactly that"
    **[HAMi](https://project-hami.io)** (a CNCF project) lets a pod ask for **an amount of GPU memory** and **a share of compute**,
    and enforces both, on any NVIDIA GPU, including our L4s:

    ```yaml
    limits:
      nvidia.com/gpu: 1          # one (virtual) GPU
      nvidia.com/gpumem: 4000    # 4000 MB of GPU memory
      nvidia.com/gpucores: 25    # 25% of the GPU's compute
    ```

!!! step "Everyone · Ask for 4 GB and 25%"
    ```bash
    kubectl apply -f - <<EOF
    apiVersion: v1
    kind: Pod
    metadata:
      name: probe
    spec:
      restartPolicy: Never
      nodeSelector:
        workshop.devfest/gpu-mode: hami
        workshop.devfest/table: ${TABLE}
      containers:
      - name: probe
        image: ${IMAGE}
        command: ["python3", "/scripts/probe.py"]
        env:
        - {name: LD_LIBRARY_PATH, value: /usr/local/nvidia/lib64}
        resources:
          limits: {nvidia.com/gpu: 1, nvidia.com/gpumem: ${GPU_MEM:-4000}, nvidia.com/gpucores: ${GPU_CORES:-25}}
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
        `GPU memory free / total : ~3.9 GiB / ~3.9 GiB`. Your pod now **sees a 4 GB GPU**: the rest doesn't exist for it.

    ```bash
    kubectl delete pod probe
    ```

!!! step ":material-rice: Idli · Try the 20 GiB grab again"
    **Idli only.**

    ```bash
    kubectl apply -f - <<EOF
    apiVersion: v1
    kind: Pod
    metadata:
      name: memhog
    spec:
      nodeSelector:
        workshop.devfest/gpu-mode: hami
        workshop.devfest/table: ${TABLE}
      containers:
      - name: memhog
        image: ${IMAGE}
        command: ["python3", "/scripts/memhog.py"]
        env:
        - {name: LD_LIBRARY_PATH, value: /usr/local/nvidia/lib64}
        - {name: GIB, value: "20"}
        resources:
          limits: {nvidia.com/gpu: 1, nvidia.com/gpumem: ${GPU_MEM:-4000}, nvidia.com/gpucores: 25}
        volumeMounts: [{name: scripts, mountPath: /scripts}]
      volumes:
      - name: scripts
        configMap: {name: gpu-scripts}
    EOF
    ```

    ```bash
    sleep 25; kubectl logs memhog | tail -2
    ```

    !!! see "You should see"
        `OUT OF MEMORY after 3 GiB`: Idli hits **its own** 4 GB limit.

!!! step ":material-tea: Chai · Ask for 3 GiB"
    **Chai only.**

    ```bash
    kubectl apply -f - <<EOF
    apiVersion: v1
    kind: Pod
    metadata:
      name: memhog
    spec:
      nodeSelector:
        workshop.devfest/gpu-mode: hami
        workshop.devfest/table: ${TABLE}
      containers:
      - name: memhog
        image: ${IMAGE}
        command: ["python3", "/scripts/memhog.py"]
        env:
        - {name: LD_LIBRARY_PATH, value: /usr/local/nvidia/lib64}
        - {name: GIB, value: "3"}
        resources:
          limits: {nvidia.com/gpu: 1, nvidia.com/gpumem: ${GPU_MEM:-4000}, nvidia.com/gpucores: 25}
        volumeMounts: [{name: scripts, mountPath: /scripts}]
      volumes:
      - name: scripts
        configMap: {name: gpu-scripts}
    EOF
    ```

    ```bash
    sleep 20; kubectl logs memhog | tail -2
    ```

    !!! see "You should see"
        `done. Holding 3 GiB`. **Chai is safe now**: Idli can't take Chai's memory.

!!! solution "Problem 2 · solved"
    Memory limits are **enforced per pod**. The greedy pod fails on its own; neighbours are protected.

!!! step "Everyone · Clean up, then the noisy neighbour test"
    ```bash
    kubectl delete pod --all
    ```

    **Dosa** starts the burn job with **25%** of the GPU, then Idli, Vada and Chai join with the same command, like in step 5:

    ```bash
    kubectl apply -f - <<EOF
    apiVersion: v1
    kind: Pod
    metadata:
      name: burn
      labels: {app: burn, team: ${TEAM}}
    spec:
      nodeSelector:
        workshop.devfest/gpu-mode: hami
        workshop.devfest/table: ${TABLE}
      containers:
      - name: burn
        image: ${IMAGE}
        command: ["python3", "/scripts/burn.py"]
        env:
        - {name: LD_LIBRARY_PATH, value: /usr/local/nvidia/lib64}
        resources:
          requests: {cpu: 500m, memory: 2Gi}
          limits: {nvidia.com/gpu: 1, nvidia.com/gpumem: 4000, nvidia.com/gpucores: ${GPU_CORES:-25}}
        volumeMounts: [{name: scripts, mountPath: /scripts}]
      volumes:
      - name: scripts
        configMap: {name: gpu-scripts}
    EOF
    ```

    !!! see "Dosa should see"
        A **lower** number than "Dosa alone" in step 5 (Dosa's capped at 25%), but it **barely moves** when the others join.

!!! solution "Problem 1 · tamed"
    Each pod gets its **share of compute**, so neighbours can't push you below it. Want more for one team? Give that pod a bigger `gpucores`.

!!! step "Everyone · Clean up"
    ```bash
    kubectl delete pod --all
    ```

!!! warning "Good to know"
    HAMi's limits are enforced in software, inside the container. That's great within one company. For tenants that must not trust
    each other, use **MIG**'s hardware walls.
