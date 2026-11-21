# Beyond GKE

The three sharing strategies are NVIDIA features, not GKE features. GKE packages them as node pool flags,
node labels and a managed device plugin. On any other Kubernetes cluster (self-managed, k3s on a GPU VM,
or another cloud) you build the same thing yourself with the **NVIDIA GPU Operator** and **k8s-device-plugin**.

## Mapping

| What you used today on GKE | Equivalent elsewhere |
|---|---|
| `gpu-sharing-strategy=time-sharing,max-shared-clients-per-gpu=4` on the node pool | Device plugin config `sharing.timeSlicing.resources: [{name: nvidia.com/gpu, replicas: 4}]` (ConfigMap referenced by the GPU Operator's `devicePlugin.config`) |
| "Only one shared GPU per container" (enforced by GKE) | `failRequestsGreaterThanOne: true` in the time-slicing config (it's off unless you set it) |
| `gpu-sharing-strategy=mps` | Device plugin `sharing.mps` config (k8s-device-plugin v0.15+), which runs an MPS control daemon per node |
| `gpu-partition-size=1g.5gb` | GPU Operator **MIG Manager** + node label `nvidia.com/mig.config=all-1g.5gb`, with `mig.strategy=single` or `mixed` |
| `cloud.google.com/gke-accelerator`, `…-gpu-sharing-strategy` labels | GPU Feature Discovery labels: `nvidia.com/gpu.product`, `nvidia.com/gpu.replicas`, `nvidia.com/gpu.sharing-strategy`, `nvidia.com/mig.config` |
| Driver installed and mounted at `/usr/local/nvidia` by GKE | GPU Operator driver container (or a preinstalled host driver) + NVIDIA Container Toolkit, so `nvidia-smi` is injected into containers |
| `node/accelerator/duty_cycle` in Cloud Monitoring | **dcgm-exporter** → Prometheus → Grafana (`DCGM_FI_DEV_GPU_UTIL`, `DCGM_FI_DEV_FB_USED`, …) |
| vLLM `--gpu-memory-utilization` gotcha | Exactly the same, wherever you run it |

**[HAMi](hami.md)** (CNCF) is another option here: it replaces the device plugin and lets pods request an amount of GPU memory and compute, with the limits enforced.

The **behaviour** you measured (noisy neighbours under time-slicing, caps under MPS, hard walls under MIG)
is the same on any platform, because it comes from the GPU and driver.

## Rehearsing on a non-GCP GPU box (e.g. Jarvislabs, Lambda, RunPod, on-prem)

A rented GPU instance is a good place to **rehearse the behaviour** and test your vLLM settings before the
event. It isn't a drop-in replacement for the workshop, though:

!!! warning "What's different"
    - **No GKE.** The node pool flags, `cloud.google.com/*` labels, Cloud Shell flow and Cloud Monitoring
      labs won't apply. You'd install k3s + the GPU Operator and use the mapping above.
    - **Many GPU clouds give you a container, not a VM.** Running Kubernetes (kubelet, containerd) inside
      a container usually doesn't work. Check that your instance type is a full VM with root access.
    - **MIG needs host-level control.** Enabling MIG mode (`nvidia-smi -mig 1`) and creating instances
      needs root on the host and usually a GPU reset. Container-based instances generally can't do this,
      so ask the provider whether MIG is available or preconfigured.
    - **H200 ≠ L4.** An H200 has 141 GB and far more compute. Your TFLOPS numbers and the "four Gemma
      servers fill the GPU" story will look very different. On GKE, H200 lives in large multi-GPU machine
      types, which are too expensive for a 50-person workshop.

### Quick rehearsal on a single GPU VM with k3s

```bash
# on the GPU VM (Ubuntu, NVIDIA driver already installed)
curl -sfL https://get.k3s.io | sh -
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia && helm repo update

cat > ts-config.yaml <<'EOF'
version: v1
sharing:
  timeSlicing:
    failRequestsGreaterThanOne: true
    resources:
    - name: nvidia.com/gpu
      replicas: 4
EOF
kubectl create ns gpu-operator
kubectl create configmap ts-config -n gpu-operator --from-file=any=ts-config.yaml
helm install gpu-operator nvidia/gpu-operator -n gpu-operator \
  --set driver.enabled=false \
  --set devicePlugin.config.name=ts-config --set devicePlugin.config.default=any
kubectl get node -o jsonpath='{.items[0].status.allocatable.nvidia\.com/gpu}'   # -> 4
```

Then run the Step 4 manifests with the GKE-specific `nodeSelector` lines removed. The burn, memhog and
probe scripts work unchanged.

!!! tip
    Check the [GPU Operator docs](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/) for the
    current values; options change between releases.
