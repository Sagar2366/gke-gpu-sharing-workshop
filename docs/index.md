---
hide:
  - navigation
  - toc
---

<div class="hero" markdown>

<span class="hero-kicker">DevFest Bengaluru · Hands-on workshop · 3:00–4:30 PM · beginner-friendly</span>

# One GPU, Four Teams

## Hands-on GPU sharing on Google Kubernetes Engine

GPUs are the most expensive machines in a cluster, and not every workload needs a whole one. Sit with three other people,
share **one real NVIDIA GPU** between your four "teams", and try all three ways GKE can share it.
**No Kubernetes, GPU or Google Cloud experience needed.**

[Start the workshop codelab :material-arrow-right:](codelabs/gpu-sharing-jarvislabs.md){ .md-button .md-button--primary }
[New here? Foundations first](codelabs/foundations.md){ .md-button }

</div>

## Codelabs

<div class="catalog">

<a class="catalog-card" href="codelabs/foundations.html">
  <span class="cc-cat">Get started</span>
  <span class="cc-title">GPU sharing foundations: the main points in 10 minutes</span>
  <p class="cc-desc">New to Kubernetes, GPUs or the cloud? Just the main points, with a picture and a quick check each.</p>
  <span class="cc-foot"><span>10 min · before the day</span><span class="cc-start">Start</span></span>
</a>

<a class="catalog-card" href="codelabs/gpu-sharing-jarvislabs.html">
  <span class="cc-cat">Workshop · on the day</span>
  <span class="cc-title">One GPU, Four Teams: from bare machines to shared GPUs</span>
  <p class="cc-desc">Build a Kubernetes GPU cluster live, then hit and fix one real problem after another: time-slicing, MPS, MIG, HAMi, and Gemma on vLLM.</p>
  <span class="cc-foot"><span>90 min · 3:00–4:30 PM</span><span class="cc-start">Start</span></span>
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
  <p class="cc-desc">Build today's Kubernetes GPU cluster yourself on a single L4 VM with the same scripts, then play all four teams.</p>
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
  <span class="cc-title">Build the workshop cluster on Jarvislabs (live)</span>
  <p class="cc-desc">Prepare Jarvislabs GPU VMs the day before, then build the Kubernetes cluster live on stage with one command.</p>
  <span class="cc-foot"><span>prep + 15 min live</span><span class="cc-start">Start</span></span>
</a>

</div>

## The story

It's Monday at a Bengaluru startup. Finance approved **one** L4 GPU for four teams. Each person at your table plays one:

| Team | Runs | Cares about |
|---|---|---|
| :material-food: **Dosa** | A Gemma chat assistant | Fast answers. Customers are waiting. |
| :material-rice: **Idli** | A nightly batch job | Throughput. It takes everything it can get. |
| :material-cookie: **Vada** | A data-science notebook | Idle most of the time, then suddenly busy |
| :material-tea: **Chai** | Evaluation jobs | Steady, medium load |

By the end you'll know which strategy keeps all four happy, and which one lets Idli quietly ruin Dosa's day.

## Reference

<div class="grid cards" markdown>

-   :material-file-document-outline: **[Cheat sheet](reference/cheatsheet.md)**: every flag, label and command on one page
-   :material-lifebuoy: **[Troubleshooting](reference/troubleshooting.md)**: stuck? Start here, then raise your hand
-   :material-book-alphabet: **[Glossary](reference/glossary.md)**: every term from the codelabs
-   :material-memory: **[HAMi](reference/hami.md)**: enforced GPU memory limits on shared GPUs
-   :material-kubernetes: **[Beyond GKE](reference/beyond-gke.md)**: the same strategies with the NVIDIA GPU Operator
-   :material-rocket-launch-outline: **[What's next](reference/whats-next.md)**: AICR and Agent Substrate

</div>

!!! note "Organisers"
    Setup, run of show, rehearsal checklist and table cards are in the **[Facilitator guide](facilitator/index.md)**.
    If GKE isn't available on the day, see **[Plan B · Jarvislabs](planb/index.md)**.
