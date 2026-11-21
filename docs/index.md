---
hide:
  - navigation
  - toc
---

<div class="hero" markdown>

<span class="hero-kicker">DevFest Bengaluru · Hands-on workshop · 3:00–4:30 PM · beginner-friendly</span>

# One GPU, Four Teams

## Hands-on GPU sharing on Kubernetes

GPUs are the most expensive machines in a cluster, and not every workload needs a whole one.
See how Kubernetes exposes and hands out GPUs, then try all three ways to share one: **time-slicing**, **NVIDIA MPS** and **MIG**.
**No Kubernetes, GPU or cloud experience needed.**

[Jarvislabs demo :material-arrow-right:](codelabs/jarvislabs-demo.md){ .md-button .md-button--primary }
[New here? Foundations first](codelabs/foundations.md){ .md-button }

</div>

## Codelabs

<div class="catalog">

<a class="catalog-card" href="codelabs/jarvislabs-demo.html">
  <span class="cc-cat">Workshop · Jarvislabs demo</span>
  <span class="cc-title">A 3-VM Jarvislabs demo with kubeadm</span>
  <p class="cc-desc">From your laptop: a kubeadm cluster on 3 H200 VMs in one private network, the device plugin, time-slicing, MPS, MIG, the gotchas, and Gemma on vLLM.</p>
  <span class="cc-foot"><span>90 min · instructor-led</span><span class="cc-start">Start</span></span>
</a>

<a class="catalog-card" href="codelabs/foundations.html">
  <span class="cc-cat">Get started</span>
  <span class="cc-title">GPU sharing foundations: the main points in 10 minutes</span>
  <p class="cc-desc">New to Kubernetes, GPUs or the cloud? Just the main points, with a picture and a quick check each.</p>
  <span class="cc-foot"><span>10 min · before the day</span><span class="cc-start">Start</span></span>
</a>

<a class="catalog-card" href="codelabs/gpu-sharing-jarvislabs.html">
  <span class="cc-cat">Workshop · table cluster</span>
  <span class="cc-title">One GPU, Four Teams: from bare machines to shared GPUs</span>
  <p class="cc-desc">A cluster built live with one GPU per table: hit and fix one problem after another, ending with HAMi and Gemma on vLLM.</p>
  <span class="cc-foot"><span>90 min · hands-on</span><span class="cc-start">Start</span></span>
</a>

<a class="catalog-card" href="codelabs/gpu-sharing-on-gke.html">
  <span class="cc-cat">Workshop · GKE edition</span>
  <span class="cc-title">One GPU, Four Teams: hands-on GPU sharing on GKE</span>
  <p class="cc-desc">The same workshop on Google Kubernetes Engine node pools, with Cloud Monitoring. Use it if GKE GPU quota is available.</p>
  <span class="cc-foot"><span>90 min</span><span class="cc-start">Start</span></span>
</a>

<a class="catalog-card" href="codelabs/jarvislabs-solo.html">
  <span class="cc-cat">Take home · Jarvislabs</span>
  <span class="cc-title">Run the GPU sharing labs on one Jarvislabs GPU VM</span>
  <p class="cc-desc">Build the cluster yourself on a single GPU VM with the same scripts, then play all four teams.</p>
  <span class="cc-foot"><span>90 min + VM setup</span><span class="cc-start">Start</span></span>
</a>

<a class="catalog-card" href="codelabs/own-project.html">
  <span class="cc-cat">Take home · Google Cloud</span>
  <span class="cc-title">Run the GPU sharing labs in your own Google Cloud project</span>
  <p class="cc-desc">Redeem your credits, create a project, get GPU quota, and repeat every step on GKE with one cheap L4.</p>
  <span class="cc-foot"><span>60 min + quota wait</span><span class="cc-start">Start</span></span>
</a>

<a class="catalog-card facilitator" href="codelabs/planb-build.html">
  <span class="cc-cat">Facilitator</span>
  <span class="cc-title">Build the table cluster on Jarvislabs (live)</span>
  <p class="cc-desc">Prepare Jarvislabs GPU VMs the day before, then build the table cluster live on stage.</p>
  <span class="cc-foot"><span>prep + 15 min live</span><span class="cc-start">Start</span></span>
</a>

</div>

## The story

It's Monday at a Bengaluru startup. Finance approved **one** GPU for four teams:

| Team | Runs | Cares about |
|---|---|---|
| :material-food: **Dosa** | a Gemma chat assistant | fast answers |
| :material-rice: **Idli** | a nightly batch job | throughput; takes everything it can get |
| :material-cookie: **Vada** | a data-science notebook | idle, then suddenly busy |
| :material-tea: **Chai** | evaluation jobs | steady load |

## Reference

<div class="grid cards" markdown>

-   :material-file-document-outline: **[Cheat sheet](reference/cheatsheet.md)**: flags, labels and commands on one page
-   :material-lifebuoy: **[Troubleshooting](reference/troubleshooting.md)**: when something doesn't work
-   :material-book-alphabet: **[Glossary](reference/glossary.md)**: every term from the codelabs
-   :material-memory: **[HAMi](reference/hami.md)**: enforced GPU memory limits on shared GPUs
-   :material-kubernetes: **[Beyond GKE](reference/beyond-gke.md)**: the same strategies with the NVIDIA GPU Operator anywhere
-   :material-rocket-launch-outline: **[What's next](reference/whats-next.md)**: AICR and Agent Substrate

</div>

!!! note "Organisers"
    Run of show, rehearsal checklist and table cards are in the **[Facilitator guide](facilitator/index.md)**.
    Jarvislabs options are in **[Plan B · Jarvislabs](planb/index.md)**.
