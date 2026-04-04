# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Project Does

`install.sh` is a single-file macOS setup script that checks for and installs all tools needed for AI-assisted software engineering — with a focus on Claude Code and the surrounding ecosystem. It is macOS-only and uses Homebrew as the foundation.

## Running the Script

```bash
chmod +x se-ai-macbook-setup.sh
./se-ai-macbook-setup.sh
```

Or run directly from a URL (once hosted):

```bash
curl -sSL <raw-url>/se-ai-macbook-setup.sh | bash
```

## What Gets Installed / Configured

| Phase | Tools |
|-------|-------|
| 1 Foundation | curl (pre-check), Xcode CLT, Homebrew |
| 2 Core Dev | Git 2+, Python 3.10+ (via Homebrew), Node.js 18+, SSL cert fix |
| 3 AI Tools | Claude Code (`npm -g @anthropic-ai/claude-code`), uv, GitHub CLI |
| 4 Optional | jq, Java 21 (OpenJDK), VS Code, Ghostty terminal |
| 6 SF Git Access | `git config credential.helper osxkeychain`, guided git.soma + git EMU setup |

## Script Architecture

The script is structured in clearly labelled sections:

- **Configuration** — version minimums (`MIN_PYTHON_MAJOR`, `MIN_NODE_VERSION`, etc.)
- **Output helpers** — `print_step`, `print_success`, `print_warning`, `print_error`, `explain`, `confirm`
- **Per-tool pairs** — every tool has a `check_<tool>()` that returns 0/1, and an `install_<tool>()` that runs the Homebrew or npm install
- **`main()`** — orchestrates five phases in order; each phase calls `check_X || { confirm ... && install_X; }`
- **`run_health_check()`** — prints a final summary table of all tools and their versions

## Key Design Constraints

- **macOS only** — the script exits immediately on non-Darwin systems
- **Non-destructive** — checks before installing; never overwrites existing configs
- **Interactive** — uses `confirm()` before every install; optional tools default to `[y/N]`
- **No external dependencies** — everything installs via Homebrew or npm; no Python installer scripts to download
- **Rosetta detection** — warns ARM Mac users if running under x86 emulation

## Salesforce Git Access (Phase 6)

Phase 6 is optional (`[y/N]`). It guides users through setting up two internal git environments:

- **git.soma** (`git.soma.salesforce.com`) — GitHub Enterprise on-prem. Requires IIQ `Technology-RnD-Access` AD group + manager approval. Contractors also need `Aloha - BPO GitSoma`.
- **git EMU** (`github.com`, `_sfemu` accounts) — GitHub Enterprise Managed Users. Requires clicking the "GitHub Salesforce - EMU" Okta tile, then requesting the `GHEC_<org-name>_Users` IIQ group.

Full user-facing guides are in `docs/`:
- `docs/git-soma-setup.md`
- `docs/git-emu-setup.md`

The script auto-configures `git config --global credential.helper osxkeychain` and uses `confirm`-style questions for manual steps (IIQ requests, manager approvals, PAT generation) that can't be automated.

## Adding a New Tool

1. Add a `check_<tool>()` function that prints a `print_step` line, returns 0 if found, 1 if not.
2. Add an `install_<tool>()` function that runs the install command and prints `print_success`.
3. Add a call in the appropriate phase in `main()`:
   ```bash
   check_mytool || { confirm "Install mytool?" && install_mytool; }
   ```
4. Add it to the `tools` array inside `run_health_check()` so it appears in the final summary.
