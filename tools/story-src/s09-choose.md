### Every problem we hit, and its fix

| Problem | Fix | Trade-off |
|---|---|---|
| Kubernetes can't see the GPU | **Device plugin** (NVIDIA GPU Operator) | on GKE, Google runs it for you |
| One idle pod holds a whole GPU | **Time-slicing** | noisy neighbours, no memory limits |
| Noisy neighbour, memory crashes | **MPS** | soft limits a pod can change |
| | **MIG** | big GPUs only, fixed slices |
| | **HAMi** | software limits: great inside one company |
| A model server grabs 90% of memory | a **per-pod memory limit** (HAMi), or tune each server | |

### One more problem: jobs that need several GPUs at once

!!! problem "Gang scheduling"
    A training job needs **4 GPUs at the same time**. The default scheduler starts 3 of its pods and waits for the fourth. Those 3 GPUs
    sit idle, and two such jobs can block each other forever.

!!! solution "Fix"
    A **gang scheduler** starts all of a job's pods together or none of them: **Volcano**, **Kueue** or NVIDIA's **KAI Scheduler**.
    HAMi works with Volcano. That's a workshop of its own!

### So which one should I use?

- **Bursty, trusted, dev/test** → **time-slicing** (cap memory in the app)
- **Many teams on the same GPUs, needing fair shares** → **HAMi**
- **Untrusted tenants, hard guarantees** → **MIG**
- **Big training jobs** → **whole GPUs** + a gang scheduler

<div class="quiz" data-answer="b">
  <p class="q">A startup has 10 L4s and 30 data scientists with notebooks that each need ~4 GB. What fits best?</p>
  <button data-opt="a">One whole L4 per notebook</button>
  <button data-opt="b">HAMi with a 4 GB memory limit per notebook</button>
  <button data-opt="c">MIG</button>
  <div class="explain">HAMi packs several notebooks per L4 with enforced memory limits. L4s don't support MIG, and whole GPUs would leave most of each one idle.</div>
</div>
