# Rehearsal checklist

Run a **full rehearsal** a week before, with `TABLES=1 MIG_NODES=1`, and use a **second Google account that is not a
project owner** as the attendee. Some details in the labs depend on the exact versions you deploy.
Verify each one below and update the sample outputs in the lab pages with **your** numbers.

## Platform

- [ ] `05-smoke-test.sh` prints a device name on **all three** pools. If PyTorch can't see the GPU, the image's
      CUDA build is probably newer than the GKE `latest` driver supports. Pin an older `IMAGE` tag or a newer GKE version.
- [ ] `04-prepull-and-cache.sh` completes. The hostPath `/var/lib/workshop/hf` is writable on Container-Optimized OS nodes.
      If it isn't, change `MODEL_CACHE_HOSTPATH` (and the path in Step 8) to a writable location.
- [ ] Time to pull `IMAGE` onto a fresh node: ______ min. (This tells you how early to run 04.)
- [ ] MIG node shows `nvidia.com/gpu: 7` after its reboot.

## As the attendee account

- [ ] `source scripts/attendee/setup.sh t01 dosa` works from a fresh Cloud Shell.
- [ ] `kubectl get nodes`, `kubectl describe node`, `kubectl exec`, `kubectl port-forward` all work.
- [ ] Metrics Explorer opens for the workshop project, and the PromQL in Step 5 returns data.
- [ ] `bash scripts/attendee/watch-gpu.sh` prints numbers.

## Lab behaviour (record your numbers)

| Check | Expected | Yours |
|---|---|---|
| Step 3 probe on L4: SMs / total GiB | ~58 / ~22 | |
| Step 4 Dosa alone, TFLOPS | some baseline | |
| Step 4 Dosa with 3 neighbours | ~¼ of baseline | |
| Step 4 Chai OOMs after Idli takes 20 GiB | OOM | |
| Step 4 2-GPU pod | `UnexpectedAdmissionError` | |
| Step 6 no `hostIPC` | error or hang | |
| Step 6 MPS probe: thread % / mem limit / SMs | 25 / ~5.5G / ~14 | |
| Step 6 Dosa alone vs. with 3 neighbours | roughly equal | |
| Step 6 memhog under MPS | OOM at ~5 GiB | |
| Step 6 override to `0=16G` | **record what happens**, and edit the page text to match | |
| Step 6 2-share pod on MPS | allowed, ~50% | |
| Step 7 MIG probe: SMs / total GiB | ~14 / ~4.8 | |
| Step 8 second vLLM at 0.9 | crash with a free-memory error (**copy the exact message into the page**) | |
| Step 8 four vLLM at 0.2 all Ready | yes | |
| Step 8 latency with/without burn | higher with burn | |
| vLLM pod start-up time from cache | ______ s | |

!!! note "vLLM version matters"
    How `--gpu-memory-utilization` treats memory used by *other* processes has changed between vLLM releases.
    With your pinned version, confirm that the fourth 0.2 server still starts and gets a reasonable KV cache.
    If it doesn't, drop to `0.18` or `--max-model-len=2048`.

## Finale (Astronomy Shop)

- [ ] `07-otel-demo.sh` completes; all `otel-demo` pods `Running` on CPU nodes, `gemma4` on the stage GPU `t00`.
- [ ] The Gemma 4 image starts with `vllm.entrypoints.openai.api_server` and `--tool-call-parser=gemma4`. If not, use the image/args from the [GKE Gemma 4 tutorial](https://cloud.google.com/kubernetes-engine/docs/tutorials/serve-gemma-gpu-vllm).
- [ ] The chart version still has the `agent` component and the `LLM_BASE_URL` / `LLM_MODEL` / `USE_VCR` env keys (`helm show values`). Pin `CHART_VERSION`.
- [ ] `/chatbot/` answers using the live model (check `kubectl -n otel-demo logs deploy/gemma4` for requests).
- [ ] Jaeger shows an LLM span under service `agent`. Note its name: ______
- [ ] Noisy neighbour ON makes the LLM span noticeably longer: quiet ____ s, noisy ____ s.
- [ ] vLLM metrics appear in the demo's Grafana/Prometheus (annotation discovery). If not, show Cloud Monitoring instead.

## Logistics

- [ ] Attendee CSV uses the **Google account emails** people will sign in with (not work SSO addresses that aren't Google accounts).
- [ ] Repo URL in Step 2 and the take-home page points at your fork.
- [ ] Table cards printed, with a spare table id or two for walk-ins.
- [ ] Teardown tested: `99-teardown.sh` leaves no GPU VMs behind.
