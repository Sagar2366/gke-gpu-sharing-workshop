!!! abstract "What you'll see"
    NVIDIA has two built-in answers to time-slicing's problems. The instructor demos both (they need special setup, or a much
    bigger GPU). Watch the big screen.

=== ":material-call-split: MPS · assigned seats"

    !!! screen "On the big screen"
        ```bash
        ROLE=stage ./scripts/jarvislabs/04-switch-strategy.sh mps
        ./scripts/jarvislabs/demo.sh mps
        ```

        Four `burn` pods on that GPU: each is **capped at ~25%** of the cores and ~5 GB of memory, and the speed **stays steady**
        when neighbours start.

    !!! problem "But"
        The caps are environment variables (`CUDA_MPS_*`) that a pod can **change itself**, pods need special access (`hostIPC`),
        and one crashing pod can affect the others.

=== ":material-view-grid: MIG · separate slices"

    !!! screen "On the big screen"
        ```bash
        kubectl get nodes -l workshop.devfest/role=mig -o custom-columns='NODE:.metadata.name,SLICES:.status.allocatable.nvidia\.com/gpu'
        ./scripts/jarvislabs/demo.sh mig
        ```

        One **H200** is cut **in hardware** into 7 slices (`1g.18gb`). A pod on one slice can't see, slow down or crash the others.

    !!! problem "But"
        Only on big, expensive GPUs (A100, H100, H200…), the slice sizes are **fixed**, and one pod gets one slice.

!!! question "Talk at your table (1 minute)"
    You have a room full of **L4s** (no MIG), and you want each team to get **a fixed amount of GPU memory** that nobody can take
    away. Which of the two helps?

    ??? success "Answer"
        Neither, really: MPS limits are soft, and MIG needs bigger GPUs. That's the gap **HAMi** fills, next.

!!! screen "On the big screen · Switch the tables to HAMi"
    ```bash
    ./scripts/jarvislabs/demo.sh clean
    ./scripts/jarvislabs/04-switch-strategy.sh hami
    ```

    Installs HAMi, then on each table GPU turns NVIDIA's device plugin **off** and HAMi's **on** (~2 minutes).
