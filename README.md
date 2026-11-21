# One GPU, Four Teams: hands-on GPU sharing on Kubernetes

A 90-minute DevFest Bengaluru workshop: how Kubernetes exposes and hands out GPUs, and the three ways to share one
(time-slicing, NVIDIA MPS, MIG), with a noisy neighbour on purpose, the gotchas, and Gemma on vLLM.

## Codelabs (open them through the site: `./serve.sh`)

| Codelab | For |
|---|---|
| **Jarvislabs demo (3 VMs, kubeadm)** | instructor-led, run end to end from your laptop |
| Foundations | 10-minute primer for beginners |
| Workshop: from bare machines to shared GPUs | live-built table cluster, attendees hands-on |
| Workshop (GKE edition) | the same on Google Kubernetes Engine |
| Take home: one Jarvislabs GPU VM / your own Google Cloud project | after the event |
| Facilitator: build the table cluster live | organisers |

## Jarvislabs demo in commands (3 VMs in one VPC, kubeadm + Cilium)

```bash
# day before
cp scripts/demo/demo.conf.example scripts/demo/demo.conf      # public IP, private IP, name per VM + SSH key
export HF_TOKEN=hf_...
./scripts/demo/00-check.sh                                    # tools, SSH, GPUs, private network OK?
./scripts/demo/01-prep.sh                                     # toolkit, containerd, kubeadm, image pull on every VM

# live
source scripts/demo/env.sh                                    # in every terminal
./scripts/demo/02-control-plane.sh                            # kubeadm init + Cilium, kubectl on the laptop
./scripts/k8s/gpu-operator.sh                                 # device plugin: Kubernetes now sees GPUs
./scripts/demo/03-join.sh h200-2; ./scripts/demo/03-join.sh h200-3   # kubeadm join
NODE=h200-1 ./scripts/k8s/mode.sh ts                          # time-slicing
NODE=h200-2 ./scripts/k8s/mode.sh mps                         # MPS
NODE=h200-3 ./scripts/k8s/mode.sh mig                         # MIG
./scripts/k8s/pod.sh burn dosa idli vada chai                 # demo pods (see the codelab)
TEAM=dosa ./scripts/k8s/gemma.sh                              # Gemma on vLLM

# after
./scripts/demo/99-cleanup.sh                                  # kubeadm reset, then delete the VMs in the Jarvislabs console
```

## Run or publish the site

```bash
./serve.sh                       # http://localhost:8000
python3 tools/build_codelabs.py  # after editing any codelab source
```

Push to `main` to publish on GitHub Pages (`.github/workflows/pages.yml`; Settings → Pages → Source: GitHub Actions).

## Layout

```
scripts/demo/          Jarvislabs demo: 00-check, 01-prep, 02-control-plane (kubeadm init), 03-join, tunnel, pulled, 99-cleanup, env.sh
scripts/k8s/           any cluster: gpu-operator, mode (exclusive|ts|mps|mig|hami), pod.sh, gemma.sh, monitoring, hami-install
scripts/node/          run on a VM: prep.sh, kubeadm-prep.sh, k3s-single.sh, join-agent.sh
scripts/jarvislabs/    live-built table cluster (k3s), used by the "from bare machines" workshop
scripts/facilitator/   GKE cluster, attendees, finale (Astronomy Shop)
scripts/attendee/      setup.sh, bench.sh, watch-gpu.sh
workloads/             probe.py, burn.py (CPU or GPU), memhog.py
tools/                 codelab sources (story-src, lab-src, src) + build_codelabs.py, codelabs.yml
docs/                  the site (MkDocs Material)
```

Replace `YOUR-ORG` (the repo URL) in the codelab sources and rebuild before the event.
