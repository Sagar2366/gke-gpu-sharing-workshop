# Kubernetes basics

**Kubernetes runs your programs on a group of machines and decides which machine each one goes on.**

<div class="hotspots">
  <div class="hs-stage">
    <img src="../assets/k8s-cluster.svg" alt="A Kubernetes cluster: a control plane and three nodes, one of them running four pods that share a GPU">
    <button class="hs" style="left:4%;top:9%" data-title="Cluster" data-text="All the machines, managed together. Everyone at the workshop shares one.">1</button>
    <button class="hs" style="left:15.6%;top:52%" data-title="Scheduler" data-text="Picks <b>which node</b> each pod runs on, looking for free CPU, memory and GPU slots.">2</button>
    <button class="hs" style="left:41%;top:21%" data-title="Node" data-text="One machine. Some nodes have a GPU attached.">3</button>
    <button class="hs" style="left:63.7%;top:34.8%" data-title="Pod" data-text="One running copy of your program. Each of you works in your own <b>namespace</b> (e.g. t07-dosa).">4</button>
    <button class="hs" style="left:63.7%;top:83.8%" data-title="GPU" data-text="One physical GPU. Today, four pods share it.">5</button>
  </div>
  <div class="hs-panel"></div>
</div>

- **Node** = a machine · **Pod** = your running program · **Namespace** = your private area · **YAML** = how you describe what you want
- A pod asks for a GPU with **`nvidia.com/gpu: 1`**, and picks *which* nodes with a **`nodeSelector`** (labels on the node).

The four commands you'll use all day:

| Command | Does |
|---|---|
| `kubectl apply -f -` | create what the YAML you paste describes |
| `kubectl get pods` | list your pods and their status |
| `kubectl logs <pod>` | show what it printed (add `-f` to follow; ++ctrl+c++ to stop) |
| `kubectl delete pod <pod>` | remove it |

!!! tip "Stuck pod?"
    `kubectl describe pod <name>` and read the **Events** at the bottom. It tells you why.

### Quick check

<div class="quiz" data-answer="a">
  <p class="q">Which line in a pod's YAML asks for a GPU?</p>
  <button data-opt="a"><code>nvidia.com/gpu: 1</code></button>
  <button data-opt="b"><code>kind: Pod</code></button>
  <button data-opt="c"><code>image: vllm/vllm-openai</code></button>
  <div class="explain">GPUs are requested as a whole number under <code>resources.limits</code>.</div>
</div>
