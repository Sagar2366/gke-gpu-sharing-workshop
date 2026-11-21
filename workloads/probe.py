"""probe.py: print what this container can see of the GPU.

Used in every lab to compare time-sharing, MPS and MIG side by side.
"""
import os
import socket

import torch

pod = os.environ.get("HOSTNAME", socket.gethostname())
print(f"pod                     : {pod}")
print(f"CUDA_VISIBLE_DEVICES    : {os.environ.get('CUDA_VISIBLE_DEVICES', '(unset)')}")

mps_vars = {k: v for k, v in os.environ.items() if k.startswith("CUDA_MPS")}
if mps_vars:
    for k in sorted(mps_vars):
        print(f"{k:<24}: {mps_vars[k]}")
else:
    print("CUDA_MPS_* variables    : none (not an MPS node)")

if not torch.cuda.is_available():
    print("torch.cuda.is_available(): False  <- the container cannot reach a GPU")
    raise SystemExit(1)

props = torch.cuda.get_device_properties(0)
free, total = torch.cuda.mem_get_info()
print(f"device                  : {props.name}")
print(f"SMs visible             : {props.multi_processor_count}")
print(f"GPU memory free / total : {free / 2**30:.1f} GiB / {total / 2**30:.1f} GiB")
