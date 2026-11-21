# One GPU, Four Teams: hands-on GPU sharing on Kubernetes

A 90-minute DevFest Bengaluru workshop: how Kubernetes exposes and hands out GPUs, and four ways to share one
(time-slicing, NVIDIA MPS, MIG and HAMi), with a noisy neighbour on purpose, the gotchas, and Gemma on vLLM.

## The session: concepts, then two labs

| Part | Codelab | Who |
|---|---|---|
| 1 | **Concepts**: the 5-layer GPU stack, how Kubernetes hands out a GPU, 4 ways to share, how HAMi works | everyone (15 min) |
| 2 | **Lab 1: real GPUs, live**: kubeadm + Cilium on 3 Jarvislabs H200s, time-slicing, MPS, MIG, HAMi, Gemma on vLLM, the GKE way of each | instructor (35 min) |
| 3 | **Lab 2: HAMi on your laptop**: kind + two fake A100s + the real HAMi scheduler | attendees (35 min, setup at home) |

Every command is written out in the codelabs, with a one-line comment; nothing runs from a hidden script.
Older codelabs (Foundations, the table-cluster workshop, the GKE edition, take-home labs) are still on the site.

Concepts and Lab 2 follow the HAMi workshop: [concepts](https://workshop.project-hami.io/concepts/gpu-stack/) and the
[ContainerDays lab](https://workshop.project-hami.io/labs/containerdays-singapore/). Lab 1's cluster follows
[Creating a cluster with kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/).

## Run or publish the site

```bash
./serve.sh                       # http://localhost:8000
python3 tools/build_codelabs.py  # after editing any codelab source
```

Push to `main` to publish on GitHub Pages (`.github/workflows/pages.yml`; Settings → Pages → Source: GitHub Actions).

## Layout

```
scripts/demo/          optional shortcuts for Lab 1 (the codelab shows the commands instead)
scripts/k8s/           any cluster: gpu-operator, mode (exclusive|ts|mps|mig|hami), pod.sh, gemma.sh, monitoring, hami-install
scripts/node/          run on a VM: prep.sh, kubeadm-prep.sh, k3s-single.sh, join-agent.sh
scripts/jarvislabs/    live-built table cluster (k3s), used by the "from bare machines" workshop
scripts/facilitator/   GKE cluster, attendees, finale (Astronomy Shop)
scripts/attendee/      setup.sh, bench.sh, watch-gpu.sh
workloads/             probe.py, burn.py (CPU or GPU), memhog.py
tools/                 codelab sources (story-src, lab-src, src) + build_codelabs.py, codelabs.yml
docs/                  the site (MkDocs Material)
```

