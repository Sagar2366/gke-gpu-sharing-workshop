!!! solution "Fix · Time-slicing"
    The GPU now **takes turns** between up to 4 pods, like four passengers sharing one auto-rickshaw. All four teams fit.
    Let's see what that costs.

!!! step ":material-food: Dosa · Start a GPU-hungry job and watch its speed"
    **Dosa only.** `burn.py` keeps the GPU busy and prints its speed (TFLOPS) every 5 seconds:

    {{BURN_TSJ}}

    ```bash
    kubectl logs -f burn          # Ctrl+C stops watching; the pod keeps running
    ```

    !!! see "You should see"
        After ~30 s: `10:42:05 [burn]   71.8 TFLOPS`. **Write this number on your table card** as *"Dosa alone"*.

!!! step ":material-rice: Idli, :material-cookie: Vada, :material-tea: Chai · Join in"
    **One at a time** (Idli first), run the same command:

    {{BURN_TSJ}}

    !!! see "Dosa should see"
        The number **drop** with each new neighbour, to about **a quarter**. Write it down as *"Dosa with 3 neighbours"*.

!!! problem "Problem 1 · The noisy neighbour"
    Nobody touched Dosa's pod, yet it got 4× slower. With time-slicing, **your speed depends on your neighbours**.
    No priorities, no limits.

!!! step "Idli, Vada, Chai · Stop your jobs"
    ```bash
    kubectl delete pod burn
    ```

!!! step ":material-rice: Idli · Grab 20 GiB of GPU memory"
    **Idli only.**

    {{MEMHOG_TSJ:20}}

    ```bash
    sleep 25; kubectl logs memhog | tail -2
    ```

    !!! see "You should see"
        `done. Holding 20 GiB until the pod is deleted.` Nothing stopped Idli.

!!! step ":material-tea: Chai · Ask for just 4 GiB"
    **Chai only.**

    {{MEMHOG_TSJ:4}}

    ```bash
    sleep 20; kubectl logs memhog | tail -2
    ```

    !!! see "You should see"
        `OUT OF MEMORY after 1 GiB: CUDA out of memory...`

!!! problem "Problem 2 · No memory limits"
    The pod that crashed is **Chai's**, the polite one, not Idli's, the greedy one. Time-slicing shares the GPU's memory with
    **no limits**: whoever asks next fails.

!!! step "Everyone · Clean up"
    ```bash
    kubectl delete pod --all
    ```

!!! step extra "Ask for two shared GPUs"
    Change `nvidia.com/gpu: 1` to `2` in the burn YAML and apply it as a pod named `greedy`. It fails with `UnexpectedAdmissionError`:
    on a time-sliced GPU a pod can ask for only **one** slot, because a slot is a turn in the queue, not a slice of the chip.

!!! tip "Look at the projector"
    The instructor shows **Grafana**'s GPU dashboard: your table's GPU at 100% busy. Can it tell *which team* is to blame?
    **No**: GPU metrics are per GPU, not per pod.
