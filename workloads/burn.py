"""burn.py: a deliberately GPU-hungry workload (the "noisy neighbour").

Runs fp16 matrix multiplies forever and prints achieved TFLOPS every few
seconds, so you can watch your throughput change when neighbours start.

Env vars:
  MATRIX        matrix size N (default 8192)
  REPORT_EVERY  seconds between reports (default 5)
  DUTY          fraction of time to stay busy, 0.1-1.0 (default 1.0)
                1.0 = greedy batch job, 0.2 = polite, bursty workload
  DEVICE        cuda (default) or cpu, to compare the same work on the CPU
"""
import os
import socket
import time

import torch

device = os.environ.get("DEVICE", "cuda")
n = int(os.environ.get("MATRIX", "8192" if device == "cuda" else "2048"))
every = float(os.environ.get("REPORT_EVERY", "5"))
duty = min(max(float(os.environ.get("DUTY", "1.0")), 0.05), 1.0)
pod = os.environ.get("HOSTNAME", socket.gethostname())

dtype = torch.float16 if device == "cuda" else torch.float32
a = torch.randn(n, n, device=device, dtype=dtype)
b = torch.randn_like(a)
c = torch.empty_like(a)
flop_per_mm = 2 * n**3

where = torch.cuda.get_device_name(0) if device == "cuda" else f"CPU ({os.cpu_count()} cores)"
print(f"[{pod}] burning {n}x{n} {str(dtype).split('.')[-1]} matmuls on {where}, duty={duty}", flush=True)

while True:
    start = time.time()
    mms = 0
    while time.time() - start < every:
        t0 = time.time()
        for _ in range(5):
            torch.matmul(a, b, out=c)
        if device == "cuda":
            torch.cuda.synchronize()
        mms += 5
        busy = time.time() - t0
        if duty < 1.0:
            time.sleep(busy * (1 - duty) / duty)
    elapsed = time.time() - start
    tflops = mms * flop_per_mm / elapsed / 1e12
    print(f"{time.strftime('%H:%M:%S')} [{pod}] {tflops:7.1f} TFLOPS", flush=True)
