# One GPU, Four Teams: hands-on GPU sharing on Kubernetes

A 90-minute workshop for DevFest Bengaluru. From your laptop, build a Kubernetes cluster out of 3 Jarvislabs H200 VMs, then show
how Kubernetes exposes and hands out GPUs, the three sharing strategies (time-slicing, NVIDIA MPS, MIG), a noisy neighbour, the
gotchas, and Gemma on vLLM. Everything is in one codelab: `docs/codelabs/workshop.md` (open it through the site).

## The whole thing in commands

```bash
# day before
cp scripts/demo/demo.conf.example scripts/demo/demo.conf      # VM IPs, SSH key, Tailscale key
export HF_TOKEN=hf_...
./scripts/demo/00-check.sh                                    # tools, SSH, GPUs OK?
./scripts/demo/01-prep.sh                                     # toolkit + helm + Tailscale on every VM

# live
source scripts/demo/env.sh                                    # in every terminal
./scripts/demo/02-control-plane.sh                            # k3s on the first VM, kubectl on the laptop
./scripts/k8s/gpu-operator.sh                                 # device plugin: Kubernetes now sees GPUs
./scripts/demo/03-join.sh h200-2; ./scripts/demo/03-join.sh h200-3
NODE=h200-1 ./scripts/k8s/mode.sh ts                          # time-slicing
NODE=h200-2 ./scripts/k8s/mode.sh mps                         # MPS
NODE=h200-3 ./scripts/k8s/mode.sh mig                         # MIG
./scripts/k8s/pod.sh burn dosa idli vada chai                 # demo pods (see the codelab)
TEAM=dosa ./scripts/k8s/gemma.sh                              # Gemma on vLLM

# after
./scripts/demo/99-cleanup.sh                                  # then delete the VMs in the Jarvislabs console
```

## Run the site

```bash
./serve.sh            # http://localhost:8000
```

To publish it on GitHub Pages, push to `main` (see `.github/workflows/pages.yml`; set Settings → Pages → Source: GitHub Actions).

## Layout

```
scripts/demo/      laptop-driven cluster: 00-check, 01-prep, 02-control-plane, 03-join, pulled, 99-cleanup, env.sh
scripts/k8s/       cluster-level: gpu-operator, mode (exclusive|ts|mps|mig|hami), pod.sh, gemma.sh, monitoring, hami-install
scripts/node/      run on a GPU VM: prep.sh (used by 01-prep)
workloads/         probe.py, burn.py (CPU or GPU), memhog.py
tools/story-src/demo-workshop.md   SOURCE of the codelab. After editing: python3 tools/build_codelabs.py
docs/              the site (MkDocs Material)
```

Older material (the GKE version, the multi-table Jarvislabs scripts) is still in `scripts/facilitator`, `scripts/jarvislabs` and
`tools/lab-src` for reference, but isn't used by this codelab.
