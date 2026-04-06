# SE AI MacBook Setup

A one-shot setup script for Salesforce employees to install and configure all tools needed for AI-assisted software engineering on macOS.

## Quickstart

```bash
curl -sSL https://raw.githubusercontent.com/johnny2678/se-ai-macbook-setup/main/se-ai-macbook-setup.sh | bash
```

Or run locally:

```bash
git clone https://git.soma.salesforce.com/john-hill/se-ai-macbook-setup.git
cd se-ai-macbook-setup
chmod +x se-ai-macbook-setup.sh
./se-ai-macbook-setup.sh
```

## What It Installs

| Phase | Tools |
|-------|-------|
| 1 — Foundation | Xcode CLT, Homebrew |
| 2 — Core Dev | Git, Python 3.12, Node.js |
| 3 — AI Tools | Claude Code, uv, GitHub CLI |
| 4 — Optional | jq, Java 21, VS Code, Ghostty |
| 6 — SF Git Access | git.soma + GitHub EMU credential setup |

The script is interactive — it checks for each tool before installing and prompts before making any changes.

## Salesforce Git Access

For step-by-step guides on setting up internal git access:

- [git.soma setup](docs/git-soma-setup.md) — GitHub Enterprise (internal)
- [git EMU setup](docs/git-emu-setup.md) — GitHub Enterprise Managed Users (`_sfemu` accounts)

## Requirements

- macOS (Apple Silicon or Intel)
- Internet connection
- Salesforce Okta access
