# Cheat sheet

## This workshop's cluster

```bash
source scripts/demo/env.sh                        # in every terminal
kubectl get nodes -L workshop.devfest/gpu-mode \
  -o custom-columns='NODE:.metadata.name,MODE:.metadata.labels.workshop\.devfest/gpu-mode,GPU:.status.allocatable.nvidia\.com/gpu'
NODE=h200-1 ./scripts/k8s/mode.sh ts              # exclusive | ts | mps | mig | hami
export TABLE=h200-1                               # where pod.sh puts pods
./scripts/k8s/pod.sh burn dosa idli               # burn-cpu | burn-gpu | hold | burn | memhog <team> <GiB> | probe | greedy
./scripts/k8s/pod.sh burn dosa --show             # print the YAML instead
TEAM=dosa GPU_UTIL=0.2 ./scripts/k8s/gemma.sh     # Gemma on vLLM, 20% of the GPU
```

| Mode | Device plugin config | `nvidia.com/gpu` per H200 | Pod needs |
|---|---|---|---|
| exclusive | `none` | 1 | |
| ts (time-slicing) | `ts4` | 4 | |
| mps | `mps4` | 4 | `hostIPC: true` |
| mig | `mig` + `nvidia.com/mig.config=all-1g.18gb` | 7 | |
| hami | NVIDIA plugin off, `gpu=on` | 10 | `nvidia.com/gpumem`, `nvidia.com/gpucores` |

## On GKE (for reference)

## Node pool flags (GKE Standard)

```bash
# Time-sharing
--accelerator=type=nvidia-l4,count=1,gpu-sharing-strategy=time-sharing,max-shared-clients-per-gpu=4,gpu-driver-version=latest

# NVIDIA MPS
--accelerator=type=nvidia-l4,count=1,gpu-sharing-strategy=mps,max-shared-clients-per-gpu=4,gpu-driver-version=latest

# MIG
--accelerator=type=nvidia-tesla-a100,count=1,gpu-partition-size=1g.5gb,gpu-driver-version=latest

# MIG + time-sharing (7 slices x 3 clients = 21 slots)
--accelerator=type=nvidia-tesla-a100,count=1,gpu-partition-size=1g.5gb,gpu-sharing-strategy=time-sharing,max-shared-clients-per-gpu=3,gpu-driver-version=latest
```

## Pod spec snippets

=== "Time-sharing"

    ```yaml
    spec:
      nodeSelector:
        cloud.google.com/gke-gpu-sharing-strategy: time-sharing
        cloud.google.com/gke-max-shared-clients-per-gpu: "4"
      containers:
      - resources:
          limits: {nvidia.com/gpu: 1}      # must be 1
    ```

=== "MPS"

    ```yaml
    spec:
      hostIPC: true                        # required
      nodeSelector:
        cloud.google.com/gke-gpu-sharing-strategy: mps
      containers:
      - resources:
          limits: {nvidia.com/gpu: 1}      # >1 allowed only on single-GPU nodes
        env:                               # optional overrides
        - {name: CUDA_MPS_ACTIVE_THREAD_PERCENTAGE, value: "25"}
        - {name: CUDA_MPS_PINNED_DEVICE_MEM_LIMIT, value: "0=5G"}
    ```

=== "MIG"

    ```yaml
    spec:
      nodeSelector:
        cloud.google.com/gke-gpu-partition-size: 1g.5gb
      containers:
      - resources:
          limits: {nvidia.com/gpu: 1}      # one slice per pod
    ```

=== "Autopilot (time-sharing)"

    ```yaml
    spec:
      nodeSelector:
        cloud.google.com/gke-accelerator: nvidia-l4
        cloud.google.com/gke-accelerator-count: "1"
        cloud.google.com/gke-gpu-sharing-strategy: time-sharing
        cloud.google.com/gke-max-shared-clients-per-gpu: "4"
    ```

## Useful commands

```bash
# GPU nodes and their sharing config
kubectl get nodes -l cloud.google.com/gke-accelerator \
  -L cloud.google.com/gke-accelerator,cloud.google.com/gke-gpu-sharing-strategy,cloud.google.com/gke-max-shared-clients-per-gpu,cloud.google.com/gke-gpu-partition-size

# allocatable GPU slots per node
kubectl get nodes -o custom-columns='NODE:.metadata.name,GPU:.status.allocatable.nvidia\.com/gpu'

# who is using which node's GPU
kubectl get pods -A -o wide --field-selector spec.nodeName=<node>

# GPU device plugin and MPS daemon health
kubectl logs -n kube-system -l k8s-app=nvidia-gpu-device-plugin -c nvidia-gpu-device-plugin --tail=100 | grep -i mps

# inside a GPU container
/usr/local/nvidia/bin/nvidia-smi -L
/usr/local/nvidia/bin/nvidia-smi --query-gpu=memory.used,memory.total,utilization.gpu --format=csv
```

## Cloud Monitoring (PromQL)

```promql
kubernetes_io:node_accelerator_duty_cycle{monitored_resource="k8s_node", cluster_name="gpu-share"}
kubernetes_io:node_accelerator_memory_used{monitored_resource="k8s_node", cluster_name="gpu-share"} / 1024^3
```

## vLLM on a shared GPU

```text
--gpu-memory-utilization=0.2    # fraction of TOTAL GPU memory this server may use (default 0.9)
--max-model-len=4096            # smaller context = smaller KV cache
--max-num-seqs=16               # fewer concurrent sequences = less memory
--enforce-eager                 # skip CUDA graph capture: faster start, less memory, a bit slower
```

## Limits worth remembering

| | Value |
|---|---|
| Max containers per GPU (time-sharing, MPS) | 48 (MPS on pre-Volta: 16) |
| Max MIG instances per GPU | 7 |
| GPUs per container on time-sharing / MIG | 1 |
| Min GKE version, time-sharing (Standard) | 1.23.7-gke.1400 |
| Min GKE version, MPS (Standard) | 1.27.7-gke.1088000 |
| `CUDA_MPS_PINNED_DEVICE_MEM_LIMIT` | needs CUDA 11.5+ in the image |
