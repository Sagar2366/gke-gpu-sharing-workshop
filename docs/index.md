---
hide:
  - navigation
  - toc
---

<div class="hero" markdown>

<span class="hero-kicker">DevFest Bengaluru · Hands-on workshop · 3:00–4:30 PM</span>

# One GPU, Four Teams

## Hands-on GPU sharing on Kubernetes

GPUs are the most expensive machines in a cluster, and giving every workload a whole one isn't always necessary.
We build a Kubernetes cluster from three GPU machines, see how it exposes and hands out GPUs, and try the three
sharing strategies (time-slicing, NVIDIA MPS and MIG), breaking each one on purpose.

[Open the codelab :material-arrow-right:](codelabs/workshop.md){ .md-button .md-button--primary }

</div>

<div class="catalog">

<a class="catalog-card" href="codelabs/workshop.html">
  <span class="cc-cat">Workshop</span>
  <span class="cc-title">One GPU, Four Teams: hands-on GPU sharing on Kubernetes</span>
  <p class="cc-desc">From three bare H200 VMs to a shared GPU cluster: device plugin, time-slicing, MPS, MIG, a noisy neighbour, the gotchas, and Gemma on vLLM.</p>
  <span class="cc-foot"><span>90 min</span><span class="cc-start">Start</span></span>
</a>

</div>

## Reference

<div class="grid cards" markdown>

-   :material-file-document-outline: **[Cheat sheet](reference/cheatsheet.md)**: flags, labels and commands on one page
-   :material-lifebuoy: **[Troubleshooting](reference/troubleshooting.md)**: when something doesn't work
-   :material-book-alphabet: **[Glossary](reference/glossary.md)**: every term from the codelab
-   :material-memory: **[HAMi](reference/hami.md)**: enforced GPU memory limits on shared GPUs
-   :material-kubernetes: **[Beyond this cluster](reference/beyond-gke.md)**: the same strategies with the NVIDIA GPU Operator anywhere
-   :material-rocket-launch-outline: **[What's next](reference/whats-next.md)**: AICR and Agent Substrate

</div>
