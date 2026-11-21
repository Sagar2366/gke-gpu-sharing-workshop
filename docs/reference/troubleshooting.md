# Troubleshooting

??? failure "`get-credentials` fails / `PERMISSION_DENIED` / `Required "container.clusters.get" permission`"
    You're signed in to Cloud Shell with a different Google account from the one you registered with.
    Run `gcloud config get account`. Switch with `gcloud auth login`, or open Cloud Shell in a browser
    profile that uses your registered account. If it's the right account, ask a helper to check the attendee list.

??? failure "`Error from server (Forbidden): pods is forbidden: User … cannot create resource "pods" in namespace "default"`"
    You're in the wrong namespace. Re-run `source scripts/attendee/setup.sh <table> <team>`, or check
    `kubectl config view --minify -o jsonpath='{..namespace}'`.

??? failure "Pod stuck in `Pending`: `Insufficient nvidia.com/gpu`"
    All four slots on your table's node are taken. Run `kubectl get pods -A -o wide | grep <your-node>`
    to see who has them (yes, you can see other teams' pods; that's part of the lesson). Delete your old
    pods: `kubectl delete pod --all`. If a teammate left a pod running, ask them nicely.

??? failure "Pod stuck in `Pending`: `didn't match Pod's node affinity/selector`"
    `$TABLE` is empty or wrong. `echo $TABLE` should print something like `t07`. Re-run the setup script.

??? failure "`exceeded quota: gpu-quota`"
    Your namespace can hold at most 3 GPU requests. `kubectl get pods` and delete what you don't need.

??? failure "Pod `Failed` with `UnexpectedAdmissionError`"
    You asked for more than one `nvidia.com/gpu` on a time-sharing or MIG node. That's the Step 4 gotcha. Use 1.

??? failure "`ContainerCreating` for a long time"
    The image is big (~10 GB). Organisers pre-pull it onto GPU nodes, but a new or recreated node has to pull
    it again. `kubectl describe pod <name>` shows `Pulling image`. Wait, or tell a helper.

??? failure "MPS pod hangs or `torch.cuda.is_available(): False`"
    Missing `hostIPC: true`. That's the Step 6 gotcha.

??? failure "vLLM `CrashLoopBackOff`: `Free memory on device … is less than desired GPU memory utilization`"
    Another process already holds GPU memory. Lower `--gpu-memory-utilization` (`GPU_UTIL=0.2 bash /tmp/gemma.sh`).
    If a teammate still has a 0.9 server running, they need to redeploy first. That's the Step 8 gotcha.

??? failure "vLLM `CrashLoopBackOff`: `No available memory for the cache blocks` / KV cache errors"
    The budget is too small for the context length. Lower `--max-model-len` (e.g. 2048) or raise `GPU_UTIL` a little.

??? failure "vLLM fails with `LocalEntryNotFoundError` / can't find model offline"
    The model cache isn't on that node (a new or recreated node). Tell a helper. They re-run `04-prepull-and-cache.sh`.

??? failure "`curl: (7) Failed to connect to 127.0.0.1 port 8000`"
    The port-forward isn't running, or it died when the pod restarted.
    `kill %1 2>/dev/null; kubectl port-forward svc/gemma 8000:8000 >/dev/null 2>&1 &`

??? failure "Metrics Explorer shows nothing"
    Wait 2–3 minutes after starting load. Check that the query editor is in **PromQL** mode, the project
    is the workshop project, and your node name filter is correct. For MIG nodes, `duty_cycle` isn't reported at all.

??? failure "Cloud Shell disconnected / new tab has no variables"
    New tabs reload your settings from `~/.gpu-workshop-env`. If they don't, run `source scripts/attendee/setup.sh <table> <team>` again.
    Your pods keep running in the cluster.

??? failure "Paste doesn't work in Cloud Shell"
    Try ++ctrl+shift+v++, or right-click → **Paste**. On a Mac use ++cmd+v++. If the browser asks for clipboard permission, allow it.

??? failure "I pasted a block and nothing happened, or the prompt shows `>`"
    The terminal is waiting for the rest of a multi-line command (usually the closing `EOF`). Press ++ctrl+c++
    to cancel, then copy the **whole** block again using the :material-content-copy: copy button and paste it in one go.

??? failure "`echo $TABLE` prints nothing"
    This tab doesn't have your settings. Run `cd ~/gke-gpu-sharing-workshop && source scripts/attendee/setup.sh <table> <team>`.

## Jarvislabs demo (3 VMs, kubeadm)

??? failure "`00-check.sh`: no SSH or no NVIDIA driver"
    Check the IP and SSH key in `scripts/demo/demo.conf`, and that you created a **VM** (not a template instance) on Jarvislabs.
    If SSH works but `nvidia-smi` doesn't, `01-prep.sh` installs a driver; reboot the VM when the log says so and re-run it.

??? failure "`kubectl` times out after `02-control-plane.sh`"
    Port 6443 on the first VM's public IP isn't reachable from your laptop. Set `API_VIA=tunnel` in `demo.conf`, run
    `./scripts/demo/tunnel.sh` (an SSH tunnel), and `./scripts/demo/02-control-plane.sh` again to rewrite the kubeconfig.

??? failure "A node won't join (`03-join.sh`)"
    `ssh root@<ip> journalctl -u kubelet -n 30`. Usual causes: the VMs can't reach each other on their **private** IPs (check
    `PRIVATE_IP` in `demo.conf`, and `nc -vz <cp-private-ip> 6443` from that VM), or an old join left state behind
    (`ssh root@<ip> kubeadm reset -f`, then re-run `03-join.sh`).

??? failure "Node `NotReady` / Cilium pods not Running"
    Right after `kubeadm init` this is expected until Cilium is installed. Afterwards: `kubectl -n kube-system get pods -l k8s-app=cilium` and
    `kubectl -n kube-system logs ds/cilium --tail=30`. The VPC must allow the VMs to reach each other on TCP 4240 (health),
    TCP 10250 (kubelet) and UDP 8472 (Cilium's VXLAN tunnel). `POD_CIDR` (10.244.0.0/16) must not overlap the VPC's range.

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
