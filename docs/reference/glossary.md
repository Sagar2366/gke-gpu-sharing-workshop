# Glossary

| Term | Meaning |
|---|---|
| **A100 / H100 / H200** | Large NVIDIA data-centre GPUs. They support MIG. |
| **Allocatable** | How much of a resource (CPU, memory, `nvidia.com/gpu`) a node offers to pods. |
| **Billing account** | Where Google Cloud charges (and credits) go. Linked to projects. |
| **Cloud Monitoring** | Google Cloud's metrics service. GKE sends GPU metrics there automatically. |
| **Cloud Shell** | A free terminal in your browser with `gcloud` and `kubectl`. |
| **Cluster** | A set of nodes managed by one Kubernetes control plane. |
| **ConfigMap** | A Kubernetes object holding files or settings. Our three Python scripts live in one called `gpu-scripts`. |
| **Container / image** | A packaged program with its dependencies. An image is the package; a container is a running copy. |
| **CUDA** | NVIDIA's GPU programming platform. |
| **CUDA OOM** | "CUDA out of memory": the program asked for more GPU memory than was free. |
| **Deployment** | Keeps a pod running and replaces it if it dies. |
| **Device plugin** | Node software that tells Kubernetes "this node has N GPUs". GKE runs one for you. |
| **Driver** | The NVIDIA software on the node that lets programs use the GPU. |
| **Duty cycle** | % of time the GPU was busy in the last sample. Reported per node. |
| **fp16 / bf16** | 16-bit number formats used for fast AI maths. |
| **Gemma** | A family of open AI models from Google. We serve Gemma 3 1B. |
| **GKE** | Google Kubernetes Engine, Google's managed Kubernetes. |
| **`hostIPC`** | A pod setting that shares the node's inter-process communication. MPS needs it. |
| **IAM** | Google Cloud permissions: who can do what. |
| **KV cache** | Memory an LLM server keeps for the text it's working on. vLLM reserves it up front. |
| **`kubectl`** | The command-line tool for Kubernetes. |
| **L4** | A mid-range NVIDIA GPU (24 GB), common for inference. Our main GPU today. |
| **Label** | A `key: value` tag on a Kubernetes object, e.g. on nodes. |
| **MIG** | Multi-instance GPU: splitting a GPU into isolated hardware slices. |
| **MPS** | NVIDIA Multi-Process Service: several processes run on the GPU at once, each with a share. |
| **Namespace** | Your own area inside a shared cluster. |
| **Node** | A machine (VM) in the cluster. |
| **Node pool** | A group of identical nodes. On GKE, GPU sharing is configured per node pool. |
| **nodeSelector** | Pod setting: "only run me on nodes with these labels". |
| **Noisy neighbour** | Another workload on the same hardware that slows you down. |
| **`nvidia-smi`** | NVIDIA's tool to view GPUs, memory and utilisation. |
| **`nvidia.com/gpu`** | The resource name a pod requests to get a GPU (or a shared slot). |
| **Pod** | One running instance of your containers. |
| **Port-forward** | `kubectl port-forward` makes a pod's port reachable from Cloud Shell's `localhost`. |
| **Project** | A Google Cloud container for resources, permissions and billing. |
| **PromQL** | A query language for metrics, usable in Cloud Monitoring. |
| **Quota** | A per-project limit on resources, such as GPUs. |
| **Scheduler** | The part of Kubernetes that picks a node for each pod. |
| **Service** | A stable name and port for reaching pods. |
| **SM** | Streaming multiprocessor: a block of GPU cores. |
| **Taint / toleration** | A node "keep out" sign / a pod's permission to ignore it. GPU nodes are tainted so only GPU pods land there. |
| **TFLOPS** | Trillions of floating-point operations per second: our speed measurement. |
| **Time-sharing** | GPU sharing by taking turns. |
| **vLLM** | An open-source, high-throughput LLM inference server. |
| **Zone / region** | Where machines physically are (`us-central1-a` is a zone in region `us-central1`). |
