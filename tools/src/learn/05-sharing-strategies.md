# Sharing a GPU

Kubernetes hands out GPUs **whole**, even if your program uses 5%. Sharing fixes the waste. The question is **what each team gives up**.

<p class="hint">Select each tab. Think of one Bengaluru auto-rickshaw.</p>

=== ":material-clock-fast: Time-sharing"

    **Four passengers taking turns.** Everyone gets a ride; nobody knows when.

    :material-check: simple, works on any NVIDIA GPU · :material-close: speed depends on neighbours, **no memory limits**

=== ":material-call-split: MPS"

    **A shared cab with assigned seats.** Everyone rides together, each in their own seat.

    :material-check: steady speed, memory caps · :material-close: the caps are settings a pod can change

=== ":material-view-grid: MIG"

    **One big vehicle cut into separate autos.** Fully separate, but smaller.

    :material-check: real hardware walls · :material-close: only big, expensive GPUs; fixed slice sizes

You'll cause the two classic problems on purpose: a **noisy neighbour** slowing you down, and a **memory grab** crashing you.

### Quick check

<div class="quiz" data-answer="c">
  <p class="q">Your chatbot must always answer fast, next to a huge batch job. Which strategy protects it best?</p>
  <button data-opt="a">Time-sharing</button>
  <button data-opt="b">It doesn't matter</button>
  <button data-opt="c">MIG (or MPS if there's no MIG)</button>
  <div class="explain">MIG gives the chatbot its own hardware slice. With time-sharing, the batch job slows it down. You'll measure this today.</div>
</div>
