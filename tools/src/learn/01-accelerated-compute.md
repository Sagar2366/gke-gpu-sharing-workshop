# Accelerated compute

AI is mostly **huge amounts of simple maths**: multiplying big grids of numbers, billions of times.

```mermaid
flowchart LR
  subgraph CPU["CPU: a few big cores"]
    direction TB
    c1["core"] --- c2["core"]
    c3["core"] --- c4["core"]
  end
  subgraph GPU["GPU: thousands of small cores, grouped in SMs"]
    direction TB
    s1["SM"] --- s2["SM"] --- s3["SM"] --- s4["SM"]
    s5["SM"] --- s6["SM"] --- s7["SM"] --- s8["SM"]
  end
```

- **CPU**: a few powerful cores, one task after another. Great for everything else.
- **GPU**: thousands of small cores doing the same maths **at once**. Great for AI.
- **GPU memory** is a fixed size (24 GB on today's L4). Fill it and programs crash with **"CUDA out of memory"**.
- GPUs are **expensive**. One that sits 90% idle is a lot of wasted money, and that's what today is about.

| Word you'll see | Means |
|---|---|
| **SM** | a block of GPU cores (the L4 has 58) |
| **TFLOPS** | trillions of maths operations per second: our speedometer |

### Quick check

<div class="flipcards">
  <div class="flip">
    <div class="front"><p>Thousands of small cores doing maths at the same time.</p></div>
    <div class="back"><p><b>GPU</b></p></div>
  </div>
  <div class="flip">
    <div class="front"><p>What happens when GPU memory is full?</p></div>
    <div class="back"><p>The next program to ask for memory crashes: <b>CUDA out of memory</b>.</p></div>
  </div>
</div>
