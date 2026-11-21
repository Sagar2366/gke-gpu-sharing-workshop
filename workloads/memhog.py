"""memhog.py: grab GPU memory 1 GiB at a time, then hold it.

Shows whether a sharing strategy enforces a memory boundary.

Env vars:
  GIB   how many GiB to try to allocate (default 20)
"""
import os
import socket
import time

import torch

target = int(os.environ.get("GIB", "20"))
pod = os.environ.get("HOSTNAME", socket.gethostname())
held = []

print(f"[{pod}] trying to allocate {target} GiB on {torch.cuda.get_device_name(0)}", flush=True)
for i in range(target):
    try:
        held.append(torch.ones(2**30, dtype=torch.uint8, device="cuda"))
    except torch.cuda.OutOfMemoryError as err:
        print(f"[{pod}] OUT OF MEMORY after {i} GiB: {str(err).splitlines()[0]}", flush=True)
        break
    free, total = torch.cuda.mem_get_info()
    print(f"[{pod}] holding {i + 1:>2} GiB | device free {free / 2**30:5.1f} of {total / 2**30:5.1f} GiB", flush=True)
    time.sleep(0.3)

print(f"[{pod}] done. Holding {len(held)} GiB until the pod is deleted.", flush=True)
while True:
    time.sleep(3600)
