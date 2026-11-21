# Step 2 · Setup

<div class="lesson-head" markdown>
<span class="pill">Module 2 · Step 2 of 7</span>
<span class="pill time">:material-timer-outline: 15 min</span>
<span class="pill who">:material-account-group: whole table</span>
[Skip to Step 3 :material-arrow-right:](01-gpu-to-pod.md){ .skip }
</div>

## Connect and run your first pod

!!! abstract "What you'll do"
    Once the cluster is ready, pick your team, connect to the cluster, and run a tiny practice pod.
    By the end you'll know the four commands you'll use all day.

    **New to Kubernetes?** Keep [Kubernetes basics](../learn/03-kubernetes-basics.md) open in another tab.

!!! step "Find your table and pick a team"
    Look at the **table card** in front of you. It shows your **table id**, such as `t07`.

    Agree with the people at your table who plays which team. Write your names on the card.

    | Team | You'll be the one who… |
    |---|---|
    | `dosa` | serves the Gemma chat assistant (needs fast answers) |
    | `idli` | runs the greedy batch job (the noisy neighbour) |
    | `vada` | runs a bursty notebook |
    | `chai` | runs steady evaluation jobs |

    !!! why "Fewer than four people?"
        No problem. Pick any free team names. Each lab has a **Solo mode** tip for missing teams.

??? note "Missed the previous step? Open Cloud Shell and get the repo"
    Open **[shell.cloud.google.com](https://shell.cloud.google.com)**, sign in, then run:

    ```bash
    git clone https://github.com/YOUR-ORG/gke-gpu-sharing-workshop.git
    cd gke-gpu-sharing-workshop
    ```

!!! step "Connect to the cluster as your team"
    Replace `t07` and `dosa` with **your** table and team, then run:

    ```bash
    source scripts/attendee/setup.sh t07 dosa
    ```

    !!! see "You should see"
        ```text
        =====================================================
          One GPU, Four Teams | DevFest Bengaluru
          table     : t07
          team      : dosa
          namespace : t07-dosa
          cluster   : gpu-share (us-central1-a, project ...)
        =====================================================
        ```

    !!! why "Why this matters"
        This logs `kubectl` in to the shared cluster **as you**, switches you into your own **namespace** (your private area), and saves
        your table and team so the lab commands can use them.

    ??? failure "It says `get-credentials failed`"
        You're probably signed in with a different Google account. Run `gcloud config get account` to check, and ask a helper.

??? planb "Which cluster am I on?"
    The banner's `cluster` line tells you. On the **Jarvislabs** cluster, `setup.sh` downloads your team's access file
    (it works once the instructor shows **CLUSTER READY**). On **GKE** it uses your Google account. Everything else stays the same
    unless an orange box says otherwise.

!!! step "Check your saved settings"
    ```bash
    echo "table=$TABLE team=$TEAM namespace=$NS"
    ```

    !!! see "You should see"
        ```text
        table=t07 team=dosa namespace=t07-dosa
        ```

    !!! why "Why this matters"
        Lab commands contain `${TABLE}` and `${TEAM}`. The terminal swaps in your values, so every command works for you without editing.

!!! step "Create your first pod (no GPU yet)"
    ```bash
    kubectl run hello --image=busybox --restart=Never -- echo "Hello from $TEAM at table $TABLE"
    ```

    !!! see "You should see"
        ```text
        pod/hello created
        ```

    !!! why "Why this matters"
        You just asked Kubernetes to run a tiny program. It picked a machine and started it there. This is the same thing
        you'll do with GPU programs later.

!!! step "Check its status"
    Run this a few times, until `STATUS` says `Completed`:

    ```bash
    kubectl get pods
    ```

    !!! see "You should see"
        ```text
        NAME    READY   STATUS      RESTARTS   AGE
        hello   0/1     Completed   0          6s
        ```

    !!! why "Status in one line"
        `Pending` = waiting for a machine · `ContainerCreating` = starting · `Running` = going · `Completed` = finished.

!!! step "Read what it printed"
    ```bash
    kubectl logs hello
    ```

    !!! see "You should see"
        ```text
        Hello from dosa at table t07
        ```

!!! step "Delete it"
    ```bash
    kubectl delete pod hello
    ```

    !!! see "You should see"
        ```text
        pod "hello" deleted
        ```

    !!! why "Why this matters"
        **Create → check → read → delete.** That's the loop for the whole workshop, just with bigger YAML and a GPU.

!!! step "Final check"
    ```bash
    kubectl get configmap gpu-scripts
    kubectl auth can-i create pods
    ```

    !!! see "You should see"
        A configmap called `gpu-scripts`, and the word `yes`.

    !!! why "What's in `gpu-scripts`?"
        Three small Python programs the labs use:

        | Script | What it does |
        |---|---|
        | `probe.py` | Prints what your container can see of the GPU: name, cores (SMs), free memory |
        | `burn.py` | Keeps the GPU 100% busy and prints its speed in **TFLOPS** every 5 s. This is the noisy neighbour. |
        | `memhog.py` | Grabs GPU memory 1 GiB at a time |

!!! step extra "Peek at the whole cluster"
    ```bash
    kubectl get nodes
    ```

    These are all the machines everyone in the room is sharing. You'll look closer in Step 3.

!!! checkpoint "Checkpoint"
    Your hello pod printed a message, `can-i` said `yes`, and `echo $NS` shows your namespace.
    **You're ready for [Step 3](01-gpu-to-pod.md).**

!!! tip "Opening a new terminal tab later?"
    Click **+** in Cloud Shell. Your table and team load automatically. If not, run
    `cd ~/gke-gpu-sharing-workshop && source scripts/attendee/setup.sh <table> <team>`.
