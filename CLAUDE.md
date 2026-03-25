# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

OTO-labs is the lab guide and tooling setup repository for the **Offensive Tooling for Operators** security training course. It is an MkDocs-based documentation site paired with shell scripts that configure a Debian-based ParrotOS VM ("The Forge") used as an attacker machine in a GOAD (Game of Active Directory) lab environment.

The lab guide is served locally from The Forge VM using the `run-labs` alias. The target environment consists of two Windows VMs: `GOAD-DC02` (192.168.56.11) and `GOAD-SRV02` (192.168.56.22).

## Commands

### Serve the Lab Guide
```bash
run-labs          # resolves repo, activates venv, runs mkdocs serve
# or manually:
cd ~/OTO-labs && source venv/bin/activate && mkdocs serve
```

### Install/Update Tools
```bash
get-tools         # runs scripts/lab_essential_tools.sh
get-extra-tools   # runs scripts/extra_tools.sh (optional, not required for class)
```

### Setup (run once after clone)
```bash
~/OTO-labs/scripts/setup.sh
source ~/.bashrc
```

### Build the Site (static output)
```bash
source venv/bin/activate && mkdocs build
```

### Install Python Dependencies
```bash
source venv/bin/activate && pip install -r requirements.txt
```

## Architecture

### Key Files
- **`mkdocs.yml`** — Site config, navigation, theme (Material), and plugin settings. The nav structure defines the order of Day 1 and Day 2 labs.
- **`requirements.txt`** — Python packages for mkdocs. Monitored by `scripts/auto-update.sh`; pip reinstalls automatically if this file changes after a pull.
- **`scripts/aliases.sh`** — Defines `me`, `run-labs`, `get-tools`, and `get-extra-tools` aliases. Sourced by `~/.bashrc` via a line added by `setup.sh`. This is the dynamic alias system — aliases live in the repo and update automatically.
- **`scripts/setup.sh`** — One-time setup: creates venv, installs requirements, adds source line to `~/.bashrc` (idempotent), installs cron job (idempotent).
- **`scripts/auto-update.sh`** — Runs every 10 minutes via cron: `git pull --ff-only`, reinstalls pip deps if `requirements.txt` changed. Logs to `/tmp/oto-labs-update.log`.
- **`scripts/_tools_lib.sh`** — Shared library sourced by both tool scripts. Contains `FAILURES`/`FAILURE_OUTPUTS` arrays, `run_step()`, and `tools_summary_and_exit()`. Not executable (100644).
- **`scripts/lab_essential_tools.sh`** — Installs tools directly used in class labs via APT, pipx, and git clone. Run via `get-tools`. Logs to `/tmp/oto-labs-lab-tools.log`.
- **`scripts/extra_tools.sh`** — Installs optional tools not required for class (password crackers, spraying tools, network analyzers, etc.). Run via `get-extra-tools`. Logs to `/tmp/oto-labs-extra-tools.log`.
- **`LAB_TEMPLATE.md`** — Template to follow when adding new lab pages.

### Lab Content (`docs/labs/`)
Each lab is a directory with `index.md` and an `img/` subdirectory. Labs use MkDocs Material admonitions (`???+ note`, `???+ warning`, `!!!`) and the `/// caption` syntax for image captions.

### Supplemental Files (`supp/`)
- `supp/lab_files/` — Files students use during labs (wordlists, etc.)
- `supp/nessus/` — Pre-run Nessus scan results for the GOAD targets

## Git Permissions

Shell scripts must be committed as executable (`100755`). When adding new scripts:
```bash
git add --chmod=+x scripts/new-script.sh
```

Verify before committing:
```bash
git ls-files --stage scripts/
```

`aliases.sh` is `100644` (not executable — it's sourced, not run directly).

## Lab Environment Context
- The Forge VM: Debian/ParrotOS, user `telchar`, password `ridgeback`
- GOAD targets are Windows VMs reachable at `192.168.56.11` and `192.168.56.22` over a host-only VMware network
- Students should NOT expose these VMs to untrusted networks

## Claude Workflow Files

**Never create Claude workflow files inside this repo.** Plan files, superpowers spec docs, brainstorm docs, and any other Claude-internal artifacts must not be added to the OTO-labs repository (including under `docs/superpowers/` or any other subdirectory). Keep all Claude planning artifacts in `~/.claude/` only.
