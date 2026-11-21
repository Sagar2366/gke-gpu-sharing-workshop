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

## Lab 1: real GPUs (3 VMs, kubeadm)

??? failure "No SSH, or `nvidia-smi` missing on a VM"
    Check the IPs in `~/gpu-demo.env` and that you created a **VM** on Jarvislabs. No driver: on the VM,
    `apt-get install -y ubuntu-drivers-common && ubuntu-drivers install --gpgpu && reboot`. Check the driver with `lsmod | grep nvidia`.

??? failure "`kubectl` times out after `kubeadm init`"
    Port 6443 on h200-1's public IP isn't reachable from your laptop. `ssh -fN -L 6443:$P1:6443 root@$H1`, then
    `sed -i '' "s#https://$H1:6443#https://127.0.0.1:6443#" $KUBECONFIG`.

??? failure "A node won't join"
    `ssh root@<ip> journalctl -u kubelet -n 30`. Usual causes: the VMs can't reach each other on their **private** IPs
    (`ssh root@$H2 "nc -zv -w3 $P1 6443"`), or an old join left state behind (`ssh root@<ip> kubeadm reset -f`, then join again).

??? failure "Node `NotReady` / Cilium pods not Running"
    Right after `kubeadm init` this is expected until Cilium is installed. Afterwards: `kubectl -n kube-system get pods -l k8s-app=cilium`
    and `kubectl -n kube-system logs ds/cilium --tail=30`. The VPC must allow TCP 4240, TCP 10250 and UDP 8472 between the VMs.
    10.244.0.0/16 must not overlap the VPC's range.

??? failure "Pods stuck in `ContainerCreating`"
    The ~10 GB image is still downloading on that node: `ssh root@<ip> "crictl --runtime-endpoint unix:///run/containerd/containerd.sock images | grep vllm"`.

??? failure "Pod `Pending`: `Insufficient nvidia.com/gpu`"
    Expected in Problems 1 and 3. Elsewhere: all GPU slots on that node are taken (`kubectl get pods -o wide`), or the node's
    label change is still being applied (`kubectl get pods -n gpu-operator`).

??? failure "MPS pod hangs or can't see the GPU"
    MPS pods need `hostIPC: true` in the pod spec.

??? failure "MIG node never shows 7"
    `kubectl -n gpu-operator logs -l app=nvidia-mig-manager --tail=30`. If MIG mode can't be enabled inside the VM, show the MIG step as slides.

??? failure "GPU pods on h200-1 or h200-3 stay `Pending` after installing HAMi"
    HAMi's webhook sends **every** GPU pod to `hami-scheduler`, which only manages `gpu=on` nodes. Add the label
    `hami.io/webhook: ignore` to pods meant for the other nodes, or run the HAMi step last (as the codelab does).

??? failure "vLLM `CrashLoopBackOff`"
    `Free memory on device … less than desired` is the gotcha in the Gemma step: patch `--gpu-memory-utilization=0.2`. `401`/`gated repo`:
    the HF token hasn't accepted the Gemma licence; recreate the secret: `kubectl delete secret hf-token`, then step 4 of *Build the cluster*.

??? failure "`curl: (7) Failed to connect to localhost port 8000`"
    The port-forward stopped: `kill %1; kubectl port-forward svc/gemma-dosa 8000:8000 >/dev/null 2>&1 &`.

??? failure "Grafana doesn't open"
    `kubectl -n monitoring port-forward svc/monitoring-grafana 3000:80`, then open `http://localhost:3000`.

## Lab 2: HAMi on your laptop

??? failure "`kind create cluster` fails"
    Docker isn't running, or has too little memory. Start Docker Desktop/OrbStack/Colima and give it 4 CPUs and 8 GB.

??? failure "`ErrImagePull` / `ImagePullBackOff`"
    The image wasn't loaded into kind. `docker images` to check you pulled it, then `kind load docker-image <image> --name hami-lab`.

??? failure "The node shows no `nvidia.com/gpumem`"
    Wait 30 s and check again. Then `kubectl -n kube-system get pods | grep hami`: the mock device plugin must be Running, and the
    node needs **both** the `nvidia.com/gpu=20` capacity patch and the `hami.io/node-nvidia-register` annotation.

??? failure "Team pods stay `Pending` for minutes"
    The mock monitor isn't finishing bookings: check it was installed with `--set completeBinds=true`
    (`helm get values hami-mock-monitor -n kube-system`).

??? failure "`kubectl get --raw ... /proxy/metrics` returns an error"
    The pod name lookup found nothing: `kubectl -n kube-system get pods --show-labels | grep -E "hami-scheduler|mock-monitor"` and use that name.
