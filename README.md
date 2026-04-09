# SE AI Setup

A one-shot setup script for Salesforce employees to install and configure all tools needed for AI-assisted software engineering on macOS and Windows.

## Quickstart

### macOS

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

### Windows

```powershell
irm https://raw.githubusercontent.com/johnny2678/se-ai-macbook-setup/main/se-ai-windows-setup.ps1 | iex
```

Or run locally:

```powershell
git clone https://git.soma.salesforce.com/john-hill/se-ai-macbook-setup.git
cd se-ai-macbook-setup
.\se-ai-windows-setup.ps1
```

### Targeted mode (both platforms)

Install only specific components (dependencies are resolved automatically):

```bash
# macOS
./se-ai-macbook-setup.sh node git claude

# Windows
.\se-ai-windows-setup.ps1 node git claude
```

## What It Installs

| Phase | Tools | macOS | Windows |
|-------|-------|-------|---------|
| 1 — Foundation | Package manager | Xcode CLT, Homebrew | Scoop |
| 2 — Core Dev | Git, Python 3.12, Node.js | Homebrew | Scoop |
| 3 — AI Tools | Claude Code, Salesforce CLI, Heroku CLI, uv, GitHub CLI | npm / Homebrew | npm / Scoop |
| 4 — Optional | jq, Java 21, VS Code, Cursor, Ghostty | Homebrew casks | Scoop extras |
| 6 — SF Git Access | git.soma + GitHub EMU credential setup | osxkeychain | Git Credential Manager |

The script is interactive — it checks for each tool before installing and prompts before making any changes.

## Salesforce Git Access

For step-by-step guides on setting up internal git access:

- [git.soma setup](docs/git-soma-setup.md) — GitHub Enterprise (internal)
- [git EMU setup](docs/git-emu-setup.md) — GitHub Enterprise Managed Users (`_sfemu` accounts)

## Requirements

- **macOS**: Apple Silicon or Intel
- **Windows**: Windows 10+ (PowerShell 5.1+)
- Internet connection
- Salesforce Okta access
