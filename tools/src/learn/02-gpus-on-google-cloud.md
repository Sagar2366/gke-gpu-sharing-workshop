# Clusters and GPUs in the cloud

- You don't buy a GPU card; you rent a **machine that comes with GPUs**.
  - Today: **NVIDIA L4** (24 GB, good for inference) for most steps, and a big **H200 / A100** for the MIG demo.
- A **cluster** is a group of those machines running Kubernetes. A **node pool** (or group of nodes) is a set of identical machines.
- **GPU sharing is set per node pool / node, not per pod.** Your pod just picks the right node with a label.
- **Cloud Shell** ([shell.cloud.google.com](https://shell.cloud.google.com)) is a free terminal in your browser with `kubectl` ready. That's all you need today.

| | Managed (GKE) | Built by us (today, on Jarvislabs) |
|---|---|---|
| Control plane | Google runs it | k3s on a small VM |
| GPU driver + device plugin | Google installs them | the NVIDIA GPU Operator |
| Sharing setting | node pool flag | a label on each node |

!!! info "Doing it in your own cloud account later?"
    Three things to sort out first: **billing / credits**, **GPU quota** (often 0 on new accounts), and **deleting machines when you're done**.
    The take-home codelabs walk you through it.

### Quick check

<div class="quiz" data-answer="b">
  <p class="q">Where is GPU sharing switched on?</p>
  <button data-opt="a">In each pod's YAML</button>
  <button data-opt="b">On the node (pool), and pods choose it with a label</button>
  <button data-opt="c">In Cloud Shell settings</button>
  <div class="explain">The sharing strategy belongs to the node. Pods pick a node with a <code>nodeSelector</code>.</div>
</div>
