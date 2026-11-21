GPUs are the most expensive machines in a cluster. Today we start from **bare GPU machines**, build a Kubernetes cluster
**live**, and then hit one real problem after another, fixing each one as we go. Your table of four shares **one NVIDIA L4**.

<div class="journey">
<span>build the cluster</span> →
<span class="p">K8s can't see the GPU</span> → <span class="s">device plugin</span> →
<span class="p">1 pod hogs the whole GPU</span> → <span class="s">time-slicing</span> →
<span class="p">noisy neighbour + memory crash</span> → <span class="s">MPS / MIG</span> → <span class="s">HAMi limits</span> →
<span>a real model on a shared GPU</span>
</div>

### The four teams at your table

| Team | Runs | Cares about |
|---|---|---|
| :material-food: **Dosa** | a Gemma chat assistant | fast answers |
| :material-rice: **Idli** | a batch job | throughput, takes everything it can get |
| :material-cookie: **Vada** | a notebook | idle, then suddenly busy |
| :material-tea: **Chai** | evaluations | steady load |

### What you'll need

- A laptop with a browser and a Google account (for **Cloud Shell**, a free terminal in your browser)
- **No** Kubernetes or GPU experience. Every command is given. Want a 10-minute head start? [Foundations](foundations.md).

!!! info "How it works"
    **On the big screen** boxes are the instructor's commands: watch, no typing needed. Everything else is a **task** for you:
    copy, run, check **You should see**, click **Mark as done**.

**Time:** 90 minutes (3:00–4:30 PM).
