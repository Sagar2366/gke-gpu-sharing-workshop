That's all the theory you need.

- **GPUs** are fast at parallel maths, expensive, and have fixed memory.
- **Kubernetes** runs pods on nodes; pods ask for `nvidia.com/gpu: 1` and pick nodes with labels.
- **Sharing** is set on the node: **time-sharing** takes turns, **MPS** gives seats, **MIG** cuts the GPU.

**Next:** **[One GPU, Four Teams (the workshop)](gpu-sharing-jarvislabs.md)**. Keep the **[Glossary](../reference/glossary.md)** open in a tab if you like.
