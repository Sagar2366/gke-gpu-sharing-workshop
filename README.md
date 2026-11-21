# One GPU, Four Teams: Hands-On GPU Sharing on GKE

A 2-hour hands-on workshop for DevFest Bengaluru. Attendees share one NVIDIA GPU per table of four
and try GPU time-sharing, NVIDIA MPS and multi-instance GPU on GKE from Cloud Shell. They also trigger
noisy neighbours, watch them in Cloud Monitoring, and serve Gemma with vLLM on a shared GPU.

## Attendees: get on the same page in 1 minute

```bash
# in Cloud Shell (shell.cloud.google.com) or any terminal with kubectl
git clone https://github.com/YOUR-ORG/gke-gpu-sharing-workshop.git
cd gke-gpu-sharing-workshop
source scripts/attendee/setup.sh <table> <team>      # e.g. t07 dosa, once the instructor shows CLUSTER READY
```

## Facilitator: build the cluster live (Jarvislabs)

```bash
cp scripts/jarvislabs/jl.conf.example scripts/jarvislabs/jl.conf    # fill in IPs, KC_SECRET, attendee CSV
export HF_TOKEN=hf_...
./scripts/jarvislabs/00-doctor.sh        # preflight: everything OK?
./scripts/jarvislabs/prep-hosts.sh       # the day before: driver, toolkit, image, model (slow)
PAUSE=1 ./scripts/jarvislabs/up.sh       # live at 3:00 PM: ~15 min, pauses for narration
WATCH=1 ./scripts/jarvislabs/status.sh   # keep on a second screen
./scripts/jarvislabs/04-switch-strategy.sh mps|ts   # between workshop steps
./scripts/jarvislabs/reset.sh            # after a rehearsal (keeps the prep)
```

Full guide: `docs/codelabs/planb-build.md` on the site.

## Run the site

```bash
./serve.sh            # http://localhost:8000, live reload
./serve.sh lan        # share it on the venue Wi-Fi: http://<laptop-ip>:8000
```

Or without the script: `pip install -r requirements.txt && mkdocs serve`.

To publish: `mkdocs gh-deploy` (GitHub Pages), or `mkdocs build` and host the `site/` folder anywhere.
`site/` also opens straight from disk (`site/index.html`).

## Layout

```
workshop.conf              # the one file to edit: project, zone, image, model
docs/                      # the lab guide (MkDocs Material)
  codelabs/                # GENERATED Google-Codelabs-style pages (don't edit; see tools/)
  javascripts/course.js    # codelab viewer (step list, Back/Next, mins remaining), tasks, flip cards, quizzes
  reference/               # cheat sheet, troubleshooting, own-project, beyond GKE
  facilitator/             # organiser guide, run of show, rehearsal checklist, table card
scripts/facilitator/       # 01 cluster → 02 tables → 03 attendees → 04 prepull → 05 smoke → 06 dashboard → 99 teardown
scripts/attendee/          # setup.sh, watch-gpu.sh, bench.sh
workloads/                 # probe.py, burn.py, memhog.py (mounted into pods via a ConfigMap)
tools/codelabs.yml         # which sources make up each codelab, step titles and minutes
tools/lab-src/             # SOURCE of the workshop steps ({{BURN_TS}}-style snippets)
tools/src/                 # SOURCE of the foundations lessons, intro/clean-up/congrats, take-home, Plan B build
tools/build_codelabs.py    # renders labs and writes docs/codelabs/*.md. Run after every edit:
                           #   python3 tools/build_codelabs.py
```

## Before the event

1. Replace `YOUR-ORG` in `tools/lab-src/00-setup.md`, `tools/src/own-project.md` and `docs/facilitator/table-card.md`, then run `python3 tools/build_codelabs.py`.
2. Fill in `workshop.conf` and **pin `IMAGE`** to a tested tag.
3. Follow `docs/facilitator/index.md`, and do the rehearsal checklist.
