# Troubleshooting

??? failure "`00-check.sh`: no SSH or no NVIDIA driver"
    Check the IP and SSH key in `scripts/demo/demo.conf`, and that you created a **VM** (not a template instance) on Jarvislabs.
    If SSH works but `nvidia-smi` doesn't, `01-prep.sh` installs a driver; reboot the VM when the log says so and re-run it.

??? failure "`kubectl` times out after `02-control-plane.sh`"
    Port 6443 on the first VM's public IP is blocked. Install the Tailscale app on your laptop (same account), set `API_VIA=tailscale`
    in `demo.conf`, and run `02-control-plane.sh` again. Remember `source scripts/demo/env.sh` in every terminal.

??? failure "A node won't join (`03-join.sh`)"
    `ssh root@<ip> journalctl -u k3s-agent -n 30`. Usual causes: the VM isn't on Tailscale (`tailscale status`), or the
    control plane's token changed (re-run `02-control-plane.sh`, then `03-join.sh`).

??? failure "Pods stuck in `ContainerCreating`"
    The ~10 GB image is still downloading on that node: `./scripts/demo/pulled.sh`. Pin `BASE_IMAGE` in `workshop.conf` to a tag so it
    isn't re-checked each time.

??? failure "Pod `Pending`: `Insufficient nvidia.com/gpu`"
    Expected in steps 4 and 6. Elsewhere: all GPU slots on that node are taken (`kubectl get pods -o wide`), or the node's mode
    is still switching (`./scripts/k8s/mode.sh` prints the GPU column; `kubectl get pods -n gpu-operator`).

??? failure "Pod `Pending`: `didn't match Pod's node affinity/selector`"
    `$TABLE` points at the wrong node. `echo $TABLE`, then `export TABLE=h200-1` (time-slicing), `h200-2` (MPS) or `h200-3` (MIG).

??? failure "MPS pod hangs or can't see the GPU"
    MPS pods need `hostIPC: true`; `pod.sh` adds it when the node's mode is `mps`. Check: `kubectl get node h200-2 -L workshop.devfest/gpu-mode`.

??? failure "MIG node never shows 7"
    `kubectl -n gpu-operator logs -l app=nvidia-mig-manager --tail=30`. If MIG mode can't be enabled inside the VM, show the MIG step as slides.

??? failure "vLLM `CrashLoopBackOff`"
    `Free memory on device … less than desired` is the gotcha in step 10: set `GPU_UTIL=0.2`. `401`/`gated repo`: the HF token
    hasn't accepted the Gemma licence, or `HF_TOKEN` wasn't exported before `02-control-plane.sh` (re-run it).

??? failure "`curl: (7) Failed to connect to localhost port 8000`"
    The port-forward stopped: `kill %1; kubectl port-forward svc/gemma-dosa 8000:8000 >/dev/null 2>&1 &`.

??? failure "Grafana doesn't open"
    `kubectl -n monitoring port-forward svc/monitoring-grafana 3000:80`, then open `http://localhost:3000`.
