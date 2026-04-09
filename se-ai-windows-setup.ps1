# ============================================================================
# SE AI Windows Setup
# Installs all tools needed for AI-assisted software engineering on Windows
#
# Usage:
#   irm https://raw.githubusercontent.com/<org>/<repo>/main/se-ai-windows-setup.ps1 | iex
#
# Or run locally:
#   .\se-ai-windows-setup.ps1                    # full interactive setup
#   .\se-ai-windows-setup.ps1 cursor node git    # check/install specific components only
#   .\se-ai-windows-setup.ps1 -Help              # list available components
#
# ============================================================================

param(
    [switch]$Help,
    [Parameter(ValueFromRemainingArguments)]
    [string[]]$Components
)

$ErrorActionPreference = "Continue"

# ============================================================================
# CONFIGURATION
# ============================================================================

$MIN_PYTHON_MAJOR = 3
$MIN_PYTHON_MINOR = 10
$MIN_NODE_VERSION  = 18
$MIN_GIT_VERSION   = 2

# ============================================================================
# OUTPUT HELPERS
# ============================================================================

function Print-Banner {
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║              SE AI Windows Setup                                 ║" -ForegroundColor Cyan
    Write-Host "  ║       AI-Assisted Software Engineering Toolkit                   ║" -ForegroundColor Cyan
    Write-Host "  ╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Print-Step    { param([string]$msg) Write-Host "  $([char]0x25B6) " -ForegroundColor Blue -NoNewline; Write-Host $msg }
function Print-Success { param([string]$msg) Write-Host "    $([char]0x2713) " -ForegroundColor Green -NoNewline; Write-Host $msg }
function Print-Warning { param([string]$msg) Write-Host "    $([char]0x26A0) " -ForegroundColor Yellow -NoNewline; Write-Host $msg }
function Print-Error   { param([string]$msg) Write-Host "    $([char]0x2717) " -ForegroundColor Red -NoNewline; Write-Host $msg }
function Print-Info    { param([string]$msg) Write-Host "    $([char]0x2139) " -ForegroundColor Cyan -NoNewline; Write-Host $msg }
function Explain       { param([string]$msg) Write-Host "    " -NoNewline; Write-Host $msg -ForegroundColor DarkGray }

function Confirm-Action {
    param(
        [string]$Prompt,
        [string]$Default = "y"
    )
    if ($Default -eq "y") {
        $hint = "[Y/n]"
    } else {
        $hint = "[y/N]"
    }
    $response = Read-Host "    ? $Prompt $hint"
    if ([string]::IsNullOrWhiteSpace($response)) {
        return $Default -eq "y"
    }
    return $response -match "^[Yy]"
}

# ============================================================================
# OS & ARCH DETECTION
# ============================================================================

function Detect-Arch {
    switch ($env:PROCESSOR_ARCHITECTURE) {
        "AMD64" { return "x86_64" }
        "ARM64" { return "ARM64" }
        default { return "unknown" }
    }
}

# Ensure Windows — checked inside Main so 'exit' doesn't kill the terminal
# when script is run via & ([scriptblock]::Create(...))

# ============================================================================
# SCOOP
# ============================================================================

function Check-Scoop {
    Print-Step "Checking Scoop..."
    Explain "Package manager for Windows — the foundation for all other installs."
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        $ver = & scoop --version 2>$null | Where-Object { $_ -notmatch '^\s*WARN\s+scoop' } | Select-Object -First 1
        Print-Success "Scoop $ver"
        return $true
    }
    Print-Warning "Scoop not found"
    return $false
}

function Install-Scoop {
    Print-Info "Installing Scoop..."
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
    # Refresh PATH so scoop is available immediately
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "User") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    Print-Success "Scoop installed"
}

# Helper: ensure a scoop bucket is added (idempotent)
function Ensure-ScoopBucket {
    param([string]$Bucket)
    $buckets = & scoop bucket list 2>$null | Select-String -Pattern "^\s*$Bucket\s" -Quiet
    if (-not $buckets) {
        & scoop bucket add $Bucket
    }
}

# ============================================================================
# GIT
# ============================================================================

function Check-Git {
    Print-Step "Checking Git ${MIN_GIT_VERSION}+..."
    Explain "Version control — required by Claude Code, npm packages, and most AI tools."
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Print-Warning "Git not found"
        return $false
    }
    $versionStr = & git --version 2>$null
    if ($versionStr -match '(\d+)\.(\d+)\.(\d+)') {
        $major = [int]$Matches[1]
        if ($major -ge $MIN_GIT_VERSION) {
            Print-Success "Git $($Matches[0])"
            return $true
        }
        Print-Warning "Git $($Matches[0]) found, but ${MIN_GIT_VERSION}+ required"
        return $false
    }
    Print-Warning "Could not parse Git version"
    return $false
}

function Install-Git {
    Print-Info "Installing Git via Scoop..."
    & scoop install git
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "User") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    Print-Success "Git installed"
}

# ============================================================================
# PYTHON
# ============================================================================

function Check-Python {
    Print-Step "Checking Python ${MIN_PYTHON_MAJOR}.${MIN_PYTHON_MINOR}+..."
    Explain "Required for AI/ML libraries, Claude hooks, and scripting."
    if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
        Print-Warning "Python not found"
        return $false
    }
    try {
        $versionStr = & python --version 2>$null
        if ($versionStr -match '(\d+)\.(\d+)\.(\d+)') {
            $major = [int]$Matches[1]
            $minor = [int]$Matches[2]
            if ($major -gt $MIN_PYTHON_MAJOR -or ($major -eq $MIN_PYTHON_MAJOR -and $minor -ge $MIN_PYTHON_MINOR)) {
                $pyPath = (Get-Command python).Source
                Print-Success "Python $($Matches[0]) ($pyPath)"
                return $true
            }
            Print-Warning "Python $($Matches[0]) found, but ${MIN_PYTHON_MAJOR}.${MIN_PYTHON_MINOR}+ required"
            return $false
        }
    } catch {}
    Print-Warning "Could not parse Python version"
    return $false
}

function Install-Python {
    Print-Info "Installing Python via Scoop..."
    & scoop install python
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "User") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    Print-Success "Python installed"
}

# ============================================================================
# UV (fast Python package manager)
# ============================================================================

function Check-Uv {
    Print-Step "Checking uv (Python package manager)..."
    Explain "A fast drop-in replacement for pip/venv — great for AI project environments."
    if (Get-Command uv -ErrorAction SilentlyContinue) {
        $ver = & uv --version 2>$null
        Print-Success "uv $ver"
        return $true
    }
    Print-Warning "uv not found"
    return $false
}

function Install-Uv {
    Print-Info "Installing uv via Scoop..."
    & scoop install uv
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "User") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    Print-Success "uv installed"
}

# ============================================================================
# NODE.JS & NPM
# ============================================================================

function Check-Node {
    Print-Step "Checking Node.js ${MIN_NODE_VERSION}+..."
    Explain "Required for Claude Code CLI and many AI tool integrations."
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        Print-Warning "Node.js not found"
        return $false
    }
    $versionStr = & node --version 2>$null
    if ($versionStr -match 'v?(\d+)') {
        $major = [int]$Matches[1]
        if ($major -ge $MIN_NODE_VERSION) {
            $npmVer = & npm --version 2>$null
            Print-Success "Node.js $($versionStr.TrimStart('v'))  |  npm $npmVer"
            return $true
        }
        Print-Warning "Node.js $versionStr found, but ${MIN_NODE_VERSION}+ required"
        return $false
    }
    Print-Warning "Could not parse Node.js version"
    return $false
}

function Install-Node {
    Print-Info "Installing Node.js via Scoop..."
    & scoop install nodejs
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "User") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    Print-Success "Node.js installed"
}

# ============================================================================
# CLAUDE CODE
# ============================================================================

function Check-ClaudeCode {
    Print-Step "Checking Claude Code..."
    Explain "Anthropic's AI coding assistant CLI."
    if (Get-Command claude -ErrorAction SilentlyContinue) {
        $ver = & claude --version 2>$null 6>$null | Where-Object { $_ -notmatch '^\s*WARN\s' } | Select-Object -First 1
        if (-not $ver) { $ver = "(version unknown)" }
        Print-Success "Claude Code $ver"
        return $true
    }
    Print-Warning "Claude Code not installed"
    return $false
}

function Install-ClaudeCode {
    Print-Info "Installing Claude Code globally via npm..."
    & npm install -g @anthropic-ai/claude-code
    Print-Success "Claude Code installed"
    Print-Info "Run 'claude' to authenticate and start your first session"
}

# ============================================================================
# GITHUB CLI
# ============================================================================

function Check-Gh {
    Print-Step "Checking GitHub CLI..."
    Explain "Interact with GitHub repos, PRs, issues, and Actions from the terminal."
    if (Get-Command gh -ErrorAction SilentlyContinue) {
        $ver = & gh --version 2>$null | Select-Object -First 1
        Print-Success "GitHub CLI $ver"
        return $true
    }
    Print-Warning "GitHub CLI not found"
    return $false
}

function Install-Gh {
    Print-Info "Installing GitHub CLI via Scoop..."
    & scoop install gh
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "User") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    Print-Success "GitHub CLI installed"
}

# ============================================================================
# HEROKU CLI
# ============================================================================

function Check-Heroku {
    Print-Step "Checking Heroku CLI..."
    Explain "Deploy and manage apps on Heroku from the terminal."
    if (Get-Command heroku -ErrorAction SilentlyContinue) {
        $ver = & heroku --version 2>$null | Select-Object -First 1
        if (-not $ver) { $ver = "(version unknown)" }
        Print-Success "Heroku CLI $ver"
        return $true
    }
    Print-Warning "Heroku CLI not found"
    return $false
}

function Install-Heroku {
    Print-Info "Installing Heroku CLI via Scoop..."
    Ensure-ScoopBucket "extras"
    & scoop install heroku-cli
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "User") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    Print-Success "Heroku CLI installed"
    Print-Info "Run 'heroku login' to authenticate"
}

# ============================================================================
# CURL
# ============================================================================

function Check-Curl {
    Print-Step "Checking curl..."
    if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
        $ver = & curl.exe --version 2>$null | Select-Object -First 1
        if ($ver -match 'curl\s+(\S+)') {
            Print-Success "curl $($Matches[1])"
        } else {
            Print-Success "curl found"
        }
        return $true
    }
    Print-Error "curl not found — this is unusual on Windows 10+"
    return $false
}

# ============================================================================
# OPTIONAL: jq
# ============================================================================

function Check-Jq {
    Print-Step "Checking jq (JSON processor)..."
    Explain "Useful for parsing AI API responses and JSON configs in scripts."
    if (Get-Command jq -ErrorAction SilentlyContinue) {
        $ver = & jq --version 2>$null
        Print-Success "jq $ver"
        return $true
    }
    Print-Warning "jq not found"
    return $false
}

function Install-Jq {
    Print-Info "Installing jq via Scoop..."
    & scoop install jq
    Print-Success "jq installed"
}

# ============================================================================
# OPTIONAL: VS Code
# ============================================================================

function Check-VsCode {
    Print-Step "Checking VS Code..."
    Explain "Popular editor with Claude Code extension support."
    if ((Get-Command code -ErrorAction SilentlyContinue) -or
        (Test-Path "$env:LOCALAPPDATA\Programs\Microsoft VS Code\code.exe") -or
        (Test-Path "$env:ProgramFiles\Microsoft VS Code\code.exe")) {
        Print-Success "VS Code found"
        return $true
    }
    Print-Warning "VS Code not found"
    return $false
}

function Install-VsCode {
    Print-Info "Installing VS Code via Scoop..."
    Ensure-ScoopBucket "extras"
    & scoop install vscode
    Print-Success "VS Code installed"
}

# ============================================================================
# OPTIONAL: Cursor editor
# ============================================================================

function Check-Cursor {
    Print-Step "Checking Cursor..."
    Explain "AI-first code editor — supports Claude Code and Salesforce extensions."
    if ((Get-Command cursor -ErrorAction SilentlyContinue) -or
        (Test-Path "$env:LOCALAPPDATA\Programs\Cursor\cursor.exe")) {
        Print-Success "Cursor found"
        return $true
    }
    Print-Warning "Cursor not found"
    return $false
}

function Install-Cursor {
    Print-Info "Installing Cursor via Scoop..."
    Ensure-ScoopBucket "extras"
    & scoop install cursor
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "User") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    Print-Success "Cursor installed"
}

# ============================================================================
# SALESFORCE EXTENSION PACK (CURSOR)
# ============================================================================

function Check-SfExtensionCursor {
    Print-Step "Checking Salesforce Extension Pack (Cursor)..."
    Explain "Apex, metadata, org management — Salesforce tooling inside Cursor."
    if (-not (Get-Command cursor -ErrorAction SilentlyContinue)) {
        Print-Warning "Cursor not in PATH — skipping Salesforce extension check"
        return $false
    }
    $exts = & cursor --list-extensions 2>$null
    if ($exts -match 'salesforce\.salesforcedx-vscode') {
        Print-Success "Salesforce Extension Pack installed in Cursor"
        return $true
    }
    Print-Warning "Salesforce Extension Pack not installed in Cursor"
    return $false
}

function Install-SfExtensionCursor {
    Print-Info "Installing Salesforce Extension Pack in Cursor..."
    & cursor --install-extension salesforce.salesforcedx-vscode
    Print-Success "Salesforce Extension Pack installed"
}

# ============================================================================
# OPTIONAL: Ghostty terminal
# ============================================================================

function Check-Ghostty {
    Print-Step "Checking Ghostty terminal..."
    Explain "A fast, modern terminal — recommended for the best Claude Code experience."
    if (Get-Command ghostty -ErrorAction SilentlyContinue) {
        Print-Success "Ghostty found"
        return $true
    }
    Print-Warning "Ghostty not found"
    return $false
}

function Install-Ghostty {
    Print-Info "Installing Ghostty via Scoop..."
    Ensure-ScoopBucket "extras"
    & scoop install ghostty
    Print-Success "Ghostty installed"
}

# ============================================================================
# OPTIONAL: Java (for tools that need JVM)
# ============================================================================

function Check-Java {
    Print-Step "Checking Java 11+..."
    Explain "Needed by some AI-adjacent tools and code analysis engines."
    if (-not (Get-Command java -ErrorAction SilentlyContinue)) {
        Print-Warning "Java not found (optional)"
        return $false
    }
    $versionStr = & java -version 2>&1 | Select-Object -First 1
    if ($versionStr -match '(\d+)(?:\.(\d+))?') {
        $major = [int]$Matches[1]
        if ($major -ge 11) {
            Print-Success "Java $($Matches[0])"
            return $true
        }
        Print-Warning "Java $($Matches[0]) found, but 11+ recommended"
        return $false
    }
    Print-Warning "Could not parse Java version"
    return $false
}

function Install-Java {
    Print-Info "Installing OpenJDK 21 via Scoop..."
    Ensure-ScoopBucket "java"
    & scoop install openjdk21
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "User") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    Print-Success "OpenJDK 21 installed"
}

# ============================================================================
# SALESFORCE CLI
# ============================================================================

function Check-Sf {
    Print-Step "Checking Salesforce CLI..."
    Explain "Official Salesforce CLI (sf) — deploy metadata, run Apex, manage orgs."
    if (Get-Command sf -ErrorAction SilentlyContinue) {
        $ver = & sf --version 2>$null | Select-Object -First 1
        if (-not $ver) { $ver = "(version unknown)" }
        Print-Success "Salesforce CLI $ver"
        return $true
    }
    Print-Warning "Salesforce CLI not installed"
    return $false
}

function Install-Sf {
    Print-Info "Installing Salesforce CLI globally via npm..."
    & npm install -g @salesforce/cli
    Print-Success "Salesforce CLI installed"
    Print-Info "Run 'sf org login web' to authenticate to a Salesforce org"
}

# ============================================================================
# SALESFORCE GIT ACCESS (Phase 6)
# ============================================================================

function Check-GitCredentialHelper {
    # Returns $true if 'manager' is the configured credential helper (GCM)
    $helpers = & git config --global --get-all credential.helper 2>$null
    if ($helpers -match "manager") { return $true }
    return $false
}

function Setup-GitCredentialHelper {
    if (-not (Check-GitCredentialHelper)) {
        & git config --global --add credential.helper manager
        Print-Success "git credential.helper manager added (Git Credential Manager)"
    } else {
        Print-Success "git credential.helper already includes manager"
    }
}

function Check-SomaReachable {
    try {
        $response = Invoke-WebRequest -Uri "https://git.soma.salesforce.com" -UseBasicParsing -TimeoutSec 8 -MaximumRedirection 0 -ErrorAction SilentlyContinue
        return $true
    } catch {
        if ($_.Exception.Response.StatusCode.value__ -in 301, 302) {
            return $true  # Redirect means reachable (Okta SSO)
        }
        return $false
    }
}

function Check-SomaAuthenticated {
    # Check for stored credentials via GCM
    try {
        $env:GIT_TERMINAL_PROMPT = "0"
        $result = & git ls-remote --exit-code "https://git.soma.salesforce.com/john-hill/se-ai-macbook-setup.git" HEAD 2>$null
        return $LASTEXITCODE -eq 0
    } catch {
        return $false
    } finally {
        Remove-Item Env:\GIT_TERMINAL_PROMPT -ErrorAction SilentlyContinue
    }
}

function Check-EmuAuthenticated {
    try {
        $env:GIT_TERMINAL_PROMPT = "0"
        $result = & git ls-remote --exit-code "https://github.com/Authoring-Agent/agentforce-adlc.git" HEAD 2>$null
        return $LASTEXITCODE -eq 0
    } catch {
        return $false
    } finally {
        Remove-Item Env:\GIT_TERMINAL_PROMPT -ErrorAction SilentlyContinue
    }
}

function Run-GitAccessPhase {
    Write-Host ""
    Write-Host "  Phase 6: Salesforce Git Access (Optional)" -ForegroundColor White
    Write-Host "  ════════════════════════════════════════════════"
    Explain "Sets up credentials for git.soma and GitHub EMU."
    Write-Host ""

    Print-Step "Checking existing git access..."
    $somaOk = Check-SomaAuthenticated
    $emuOk  = Check-EmuAuthenticated

    if ($somaOk) { Print-Success "git.soma       - authenticated" }
    else         { Print-Warning "git.soma       - not yet configured" }
    if ($emuOk)  { Print-Success "git EMU        - authenticated" }
    else         { Print-Warning "git EMU        - not yet configured" }

    if ($somaOk -and $emuOk) {
        Print-Success "Both git environments already configured - nothing to do"
        return
    }

    Write-Host ""
    if (-not (Confirm-Action "Set up Salesforce git access now?" "n")) {
        Print-Info "Skipped. Run the script again or see docs/git-soma-setup.md and docs/git-emu-setup.md"
        return
    }

    Print-Step "Configuring git credential helper..."
    Setup-GitCredentialHelper

    # git.soma
    Write-Host ""
    if ($somaOk) {
        Print-Success "git.soma already authenticated - skipping"
    } elseif (Confirm-Action "Set up git.soma (git.soma.salesforce.com)?") {
        Write-Host ""
        Write-Host "    git.soma (GitHub Enterprise)" -ForegroundColor White
        Write-Host "    ────────────────────────────────────────"
        Explain "Internal Salesforce GitHub. Full guide: docs/git-soma-setup.md"
        Write-Host ""

        if (Confirm-Action "Have you requested 'Technology-RnD-Access' in IdentityIQ (IIQ)?") {
            Print-Success "AD group access requested"
            if (Confirm-Action "Has your manager approved the request?") {
                Print-Success "Manager approved"
                if (Confirm-Action "Can you successfully log in to git.soma.salesforce.com?") {
                    Print-Success "git.soma login confirmed"
                } else {
                    Print-Info "Access can take 4-48 hours after approval."
                    Print-Info "Try again later. See: docs/git-soma-setup.md"
                }
            } else {
                Print-Info "Follow up with your manager - they'll receive an approval email."
                Print-Info "Once approved, access propagates in ~4 hours."
            }
        } else {
            Write-Host ""
            Print-Info "To request access:"
            Print-Info "  1. Go to salesforce.okta.com -> IdentityIQ (IIQ)"
            Print-Info "  2. Click Manage User Access -> select yourself -> Next"
            Print-Info "  3. Search for 'Technology-RnD-Access' and submit with justification"
            Print-Info "  Contractors: also request 'Aloha - BPO GitSoma'"
            Print-Info "  Full guide: docs/git-soma-setup.md"
        }

        Write-Host ""
        if (Confirm-Action "Have you generated a Personal Access Token on git.soma?") {
            Print-Step "Verifying git.soma access with your PAT..."
            try {
                $env:GIT_TERMINAL_PROMPT = "0"
                & git ls-remote --exit-code "https://git.soma.salesforce.com/john-hill/se-ai-macbook-setup.git" HEAD 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Print-Success "git.soma access verified - PAT works and is cached"
                } else {
                    Print-Warning "Could not authenticate to git.soma - PAT may not be stored yet"
                    Print-Info "Clone any git.soma repo via HTTPS to trigger the credential prompt:"
                    Print-Info "  git clone https://git.soma.salesforce.com/<org>/<repo>.git"
                }
            } finally {
                Remove-Item Env:\GIT_TERMINAL_PROMPT -ErrorAction SilentlyContinue
            }
        } else {
            Print-Info "To generate a token:"
            Print-Info "  git.soma -> Profile -> Settings -> Access Tokens"
            Print-Info "  Then clone any repo via HTTPS - git will prompt for credentials."
        }
    }

    # git EMU
    Write-Host ""
    if ($emuOk) {
        Print-Success "git EMU already authenticated - skipping"
    } elseif (Confirm-Action "Set up git EMU (github.com _sfemu account)?") {
        Write-Host ""
        Write-Host "    git EMU (GitHub Enterprise Managed Users)" -ForegroundColor White
        Write-Host "    ────────────────────────────────────────"
        Explain "Salesforce orgs on github.com with _sfemu accounts. Full guide: docs/git-emu-setup.md"
        Write-Host ""

        if (Confirm-Action "Have you clicked the 'GitHub Salesforce - EMU' tile in Okta to create your EMU account?") {
            Print-Success "EMU account exists"
            if (Confirm-Action "Have you requested access to the specific GitHub org you need via IIQ?") {
                Print-Success "Org access requested"
                Print-Info "Org access can take 20 min to 4+ hours after manager approval."
                Print-Info "Check access by visiting the org URL on github.com."
            } else {
                Write-Host ""
                Print-Info "To request org access:"
                Print-Info "  1. Open IdentityIQ (IIQ) in Okta"
                Print-Info "  2. Search for 'GHEC_<org-name>_Users' (e.g. GHEC_salesforce-ux-emu_Users)"
                Print-Info "  3. Not sure which group? Use /prodeng github-access in Slack"
                Print-Info "  Full guide: docs/git-emu-setup.md"
            }
        } else {
            Write-Host ""
            Print-Info "To create your EMU account:"
            Print-Info "  1. Go to salesforce.okta.com"
            Print-Info "  2. Find and click 'GitHub Salesforce - EMU'"
            Print-Info "  Your username will end in _sfemu (e.g. jsmith_sfemu)"
            Print-Info "  Full guide: docs/git-emu-setup.md"
        }

        Write-Host ""
        if (Confirm-Action "Have you generated a Personal Access Token for your _sfemu account on github.com?") {
            Print-Step "Verifying git EMU access with your PAT..."
            try {
                $env:GIT_TERMINAL_PROMPT = "0"
                & git ls-remote --exit-code "https://github.com/Authoring-Agent/agentforce-adlc.git" HEAD 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Print-Success "git EMU access verified - PAT works and is cached"
                } else {
                    Print-Warning "Could not authenticate to GitHub EMU - PAT may not be stored yet"
                    Print-Info "Clone any EMU repo via HTTPS to trigger the credential prompt:"
                    Print-Info "  git clone https://github.com/<org>/<repo>.git"
                    Print-Info "  Use your _sfemu username and PAT as the password."
                }
            } finally {
                Remove-Item Env:\GIT_TERMINAL_PROMPT -ErrorAction SilentlyContinue
            }
        } else {
            Print-Info "To generate a token:"
            Print-Info "  github.com (logged in as _sfemu) -> Settings -> Developer settings"
            Print-Info "  -> Personal access tokens -> Tokens (classic) -> Generate new token"
            Print-Info "  Minimum scopes: repo, read:org"
        }
    }
}

# ============================================================================
# HEALTH CHECK
# ============================================================================

function Run-HealthCheck {
    param(
        [string[]]$Filter = @()
    )

    Write-Host ""
    Write-Host "  Environment Status:" -ForegroundColor White
    Write-Host "  ────────────────────────────────────────────────"

    $tools = @(
        @{ Name = "scoop";   Canonical = "scoop";  Cmd = { & scoop --version 2>$null | Select-Object -First 1 } }
        @{ Name = "git";     Canonical = "git";    Cmd = { & git --version 2>$null } }
        @{ Name = "python";  Canonical = "python"; Cmd = { & python --version 2>$null } }
        @{ Name = "uv";      Canonical = "uv";     Cmd = { & uv --version 2>$null } }
        @{ Name = "node";    Canonical = "node";   Cmd = { & node --version 2>$null } }
        @{ Name = "npm";     Canonical = "node";   Cmd = { & npm --version 2>$null } }
        @{ Name = "claude";  Canonical = "claude"; Cmd = { $v = & claude --version 2>$null 6>$null | Where-Object { $_ -notmatch '^\s*WARN\s' } | Select-Object -First 1; if ($v) { $v } else { "(run claude to authenticate)" } } }
        @{ Name = "sf";      Canonical = "sf";     Cmd = { & sf --version 2>$null | Select-Object -First 1 } }
        @{ Name = "heroku";  Canonical = "heroku"; Cmd = { & heroku --version 2>$null | Select-Object -First 1 } }
        @{ Name = "gh";      Canonical = "gh";     Cmd = { & gh --version 2>$null | Select-Object -First 1 } }
        @{ Name = "curl";    Canonical = "curl";   Cmd = { $v = & curl.exe --version 2>$null | Select-Object -First 1; if ($v -match 'curl\s+(\S+)') { "curl $($Matches[1])" } else { "found" } } }
        @{ Name = "jq";      Canonical = "jq";     Cmd = { & jq --version 2>$null } }
        @{ Name = "code";    Canonical = "vscode"; Cmd = { & code --version 2>$null | Select-Object -First 1 } }
        @{ Name = "cursor";              Canonical = "cursor";              Cmd = { & cursor --version 2>$null | Select-Object -First 1 } }
        @{ Name = "sf-extension-cursor"; Canonical = "sf-extension-cursor"; Cmd = { $exts = & cursor --list-extensions 2>$null; if ($exts -match 'salesforce\.salesforcedx-vscode') { "installed" } else { $null } } }
        @{ Name = "java";                Canonical = "java";                Cmd = { & java -version 2>&1 | Select-Object -First 1 } }
    )

    foreach ($tool in $tools) {
        # When a filter is active, skip tools not in the requested set
        if ($Filter.Count -gt 0 -and $tool.Canonical -notin $Filter) {
            continue
        }

        $cmd = Get-Command $tool.Name -ErrorAction SilentlyContinue
        # Special case: use curl.exe for curl to avoid PowerShell alias
        if ($tool.Name -eq "curl") {
            $cmd = Get-Command "curl.exe" -ErrorAction SilentlyContinue
        }

        if ($cmd) {
            try {
                $ver = & $tool.Cmd
                if (-not $ver) { $ver = "found" }
            } catch {
                $ver = "found"
            }
            Write-Host ("    {0,-20} {1}" -f $tool.Name, $ver) -ForegroundColor Green
        } else {
            Write-Host ("    {0,-20} {1}" -f $tool.Name, "not installed") -ForegroundColor Yellow
        }
    }

    # git credential helper & git.soma — only in full mode (no filter)
    if ($Filter.Count -eq 0) {
        $credHelpers = & git config --global --get-all credential.helper 2>$null
        if (-not $credHelpers) { $credHelpers = "not set" }
        if (Check-GitCredentialHelper) {
            Write-Host ("    {0,-20} {1}" -f "credential.helper", $credHelpers) -ForegroundColor Green
        } else {
            Write-Host ("    {0,-20} {1}" -f "credential.helper", $credHelpers) -ForegroundColor Yellow
        }

        if (Check-SomaReachable) {
            Write-Host ("    {0,-20} {1}" -f "git.soma", "reachable") -ForegroundColor Green
        } else {
            Write-Host ("    {0,-20} {1}" -f "git.soma", "not reachable (needs IIQ access)") -ForegroundColor Yellow
        }
    }

    Write-Host "  ────────────────────────────────────────────────"
}

# ============================================================================
# TARGETED MODE — helpers and dispatcher
# ============================================================================

# All canonical component names in dependency-safe order
$ALL_COMPONENTS = @("curl", "scoop", "git", "python", "node", "uv", "claude", "sf", "heroku", "gh", "jq", "java", "vscode", "cursor", "sf-extension-cursor", "ghostty")

function Normalize-Component {
    param([string]$Name)
    switch ($Name) {
        "homebrew"                { return "scoop" }
        "brew"                    { return "scoop" }
        "python3"                 { return "python" }
        "nodejs"                  { return "node" }
        "claude-code"             { return "claude" }
        { $_ -in "salesforce", "salesforce-cli" } { return "sf" }
        { $_ -in "github-cli", "github" }         { return "gh" }
        "heroku-cli"              { return "heroku" }
        { $_ -in "vs-code", "code" }              { return "vscode" }
        { $_ -in "sf-extension", "salesforce-extension-cursor", "sf-ext-cursor" } { return "sf-extension-cursor" }
        default                   { return $Name }
    }
}

function Get-Dependencies {
    param([string]$Component)
    switch ($Component) {
        "scoop"                   { return @() }
        { $_ -in "git", "python", "uv", "gh", "heroku", "jq", "java", "vscode", "cursor", "ghostty", "node" } { return @("scoop") }
        { $_ -in "claude", "sf" }  { return @("node") }
        "sf-extension-cursor"     { return @("cursor") }
        default                   { return @() }
    }
}

function Get-Label {
    param([string]$Component)
    switch ($Component) {
        "scoop"   { return "Scoop" }
        "git"     { return "Git" }
        "python"  { return "Python" }
        "node"    { return "Node.js" }
        "uv"      { return "uv (Python package manager)" }
        "claude"  { return "Claude Code (npm)" }
        "sf"      { return "Salesforce CLI (npm)" }
        "heroku"  { return "Heroku CLI" }
        "gh"      { return "GitHub CLI" }
        "jq"      { return "jq (JSON processor)" }
        "java"    { return "Java 21 (OpenJDK)" }
        "vscode"  { return "VS Code" }
        "cursor"              { return "Cursor" }
        "sf-extension-cursor" { return "Salesforce Extension Pack for Cursor" }
        "ghostty"             { return "Ghostty terminal" }
        default   { return $Component }
    }
}

function Check-Component {
    param([string]$Component)
    switch ($Component) {
        "curl"    { return Check-Curl }
        "scoop"   { return Check-Scoop }
        "git"     { return Check-Git }
        "python"  { return Check-Python }
        "node"    { return Check-Node }
        "uv"      { return Check-Uv }
        "claude"  { return Check-ClaudeCode }
        "sf"      { return Check-Sf }
        "heroku"  { return Check-Heroku }
        "gh"      { return Check-Gh }
        "jq"      { return Check-Jq }
        "java"    { return Check-Java }
        "vscode"  { return Check-VsCode }
        "cursor"              { return Check-Cursor }
        "sf-extension-cursor" { return Check-SfExtensionCursor }
        "ghostty"             { return Check-Ghostty }
        default   { Print-Error "Unknown component: $Component"; return $false }
    }
}

function Install-Component {
    param([string]$Component)
    switch ($Component) {
        "curl"    { return }  # no installer; script errors if curl missing
        "scoop"   { Install-Scoop }
        "git"     { Install-Git }
        "python"  { Install-Python }
        "node"    { Install-Node }
        "uv"      { Install-Uv }
        "claude"  { Install-ClaudeCode }
        "sf"      { Install-Sf }
        "heroku"  { Install-Heroku }
        "gh"      { Install-Gh }
        "jq"      { Install-Jq }
        "java"    { Install-Java }
        "vscode"  { Install-VsCode }
        "cursor"              { Install-Cursor }
        "sf-extension-cursor" { Install-SfExtensionCursor }
        "ghostty"             { Install-Ghostty }
    }
}

# Recursively expand a component and its dependencies
function Add-WithDeps {
    param(
        [string]$Component,
        [System.Collections.ArrayList]$Needed
    )
    if ($Needed.Contains($Component)) { return }
    foreach ($dep in (Get-Dependencies $Component)) {
        Add-WithDeps -Component $dep -Needed $Needed
    }
    [void]$Needed.Add($Component)
}

function Show-Help {
    Write-Host "Usage: .\se-ai-windows-setup.ps1 [component ...]"
    Write-Host ""
    Write-Host "  Checks (and optionally installs) only the specified components,"
    Write-Host "  automatically including any required dependencies."
    Write-Host ""
    Write-Host "  Run with no arguments to step through the full interactive setup."
    Write-Host ""
    Write-Host "  Components:"
    Write-Host "    curl  scoop  git  python  node  uv  claude  sf  heroku"
    Write-Host "    gh    jq     java  vscode  cursor  sf-extension-cursor  ghostty"
    Write-Host ""
    Write-Host "  Aliases:"
    Write-Host "    homebrew, brew, python3, nodejs, claude-code,"
    Write-Host "    salesforce, salesforce-cli, github-cli, heroku-cli,"
    Write-Host "    vs-code, code"
    Write-Host ""
}

function Run-Targeted {
    param([string[]]$RequestedComponents)

    $arch = Detect-Arch
    $winVer = [System.Environment]::OSVersion.Version
    Write-Host "  System Info:" -ForegroundColor White
    Write-Host "    Windows $($winVer.Major).$($winVer.Minor).$($winVer.Build)  |  arch: $arch"
    Write-Host ""

    # Normalize and validate
    $requested = @()
    foreach ($arg in $RequestedComponents) {
        $canonical = Normalize-Component $arg
        if ($canonical -notin $ALL_COMPONENTS) {
            Print-Warning "Unknown component '$arg' — skipping. Run -Help for the list of valid components."
            continue
        }
        $requested += $canonical
    }

    # Expand deps
    $needed = [System.Collections.ArrayList]::new()
    foreach ($comp in $requested) {
        Add-WithDeps -Component $comp -Needed $needed
    }

    # Report
    Write-Host "  Checking: $($requested -join ' ')" -ForegroundColor White
    $autoAdded = $needed | Where-Object { $_ -notin $requested }
    if ($autoAdded.Count -gt 0) {
        Write-Host "    + dependencies: $($autoAdded -join ' ')" -ForegroundColor DarkGray
    }
    Write-Host "  ════════════════════════════════════════════════"

    # Process in canonical order
    foreach ($comp in $ALL_COMPONENTS) {
        if ($comp -notin $needed) { continue }
        if ($comp -eq "curl") {
            if (-not (Check-Curl)) {
                Print-Error "curl is required but not found"
                return
            }
            continue
        }
        if (-not (Check-Component $comp)) {
            if (Confirm-Action "Install $(Get-Label $comp)?") {
                Install-Component $comp
            }
        }
    }

    Run-HealthCheck -Filter ([string[]]$needed)
}

# ============================================================================
# MAIN
# ============================================================================

function Main {
    if ($env:OS -ne "Windows_NT") {
        Write-Host "This script is for Windows only."
        return
    }

    Print-Banner

    if ($Help) {
        Show-Help
        return
    }

    # Targeted mode
    if ($Components -and $Components.Count -gt 0) {
        Run-Targeted $Components
        return
    }

    # Full interactive mode
    $arch = Detect-Arch
    $winVer = [System.Environment]::OSVersion.Version

    Write-Host "  System Info:" -ForegroundColor White
    Write-Host "    Windows $($winVer.Major).$($winVer.Minor).$($winVer.Build)  |  arch: $arch"
    Write-Host ""

    # ─────────────────────────────────────────────────────────────────────
    # Phase 1: Foundation
    # ─────────────────────────────────────────────────────────────────────
    Write-Host "  Phase 1: Foundation" -ForegroundColor White
    Write-Host "  ════════════════════════════════════════════════"

    if (-not (Check-Curl)) {
        Print-Error "curl is required"
        return
    }

    if (-not (Check-Scoop)) {
        if (Confirm-Action "Install Scoop?") {
            Install-Scoop
        } else {
            Print-Error "Scoop is required to install remaining tools"
            return
        }
    }

    # ─────────────────────────────────────────────────────────────────────
    # Phase 2: Core Dev Tools
    # ─────────────────────────────────────────────────────────────────────
    Write-Host ""
    Write-Host "  Phase 2: Core Dev Tools" -ForegroundColor White
    Write-Host "  ════════════════════════════════════════════════"

    if (-not (Check-Git))    { if (Confirm-Action "Install Git?")       { Install-Git } }
    if (-not (Check-Python)) { if (Confirm-Action "Install Python?")    { Install-Python } }
    if (-not (Check-Node))   { if (Confirm-Action "Install Node.js?")   { Install-Node } }

    # ─────────────────────────────────────────────────────────────────────
    # Phase 3: AI Tools
    # ─────────────────────────────────────────────────────────────────────
    Write-Host ""
    Write-Host "  Phase 3: AI Tools" -ForegroundColor White
    Write-Host "  ════════════════════════════════════════════════"

    if (-not (Check-ClaudeCode)) { if (Confirm-Action "Install Claude Code (npm)?")         { Install-ClaudeCode } }
    if (-not (Check-Sf))         { if (Confirm-Action "Install Salesforce CLI (npm)?")       { Install-Sf } }
    if (-not (Check-Heroku))     { if (Confirm-Action "Install Heroku CLI?")                 { Install-Heroku } }
    if (-not (Check-Uv))         { if (Confirm-Action "Install uv (Python package manager)?") { Install-Uv } }
    if (-not (Check-Gh))         { if (Confirm-Action "Install GitHub CLI?")                 { Install-Gh } }

    # ─────────────────────────────────────────────────────────────────────
    # Phase 4: Optional Extras
    # ─────────────────────────────────────────────────────────────────────
    Write-Host ""
    Write-Host "  Phase 4: Optional Extras" -ForegroundColor White
    Write-Host "  ════════════════════════════════════════════════"

    if (-not (Check-Jq))      { if (Confirm-Action "Install jq (JSON processor)?" "n")  { Install-Jq } }
    if (-not (Check-Java))    { if (Confirm-Action "Install Java 21 (OpenJDK)?" "n")    { Install-Java } }
    if (-not (Check-VsCode))  { if (Confirm-Action "Install VS Code?" "n")              { Install-VsCode } }
    if (-not (Check-Cursor))  { if (Confirm-Action "Install Cursor?" "n")               { Install-Cursor } }
    if (Get-Command cursor -ErrorAction SilentlyContinue) {
        if (-not (Check-SfExtensionCursor)) { if (Confirm-Action "Install Salesforce Extension Pack for Cursor?" "n") { Install-SfExtensionCursor } }
    }
    if (-not (Check-Ghostty)) { if (Confirm-Action "Install Ghostty terminal?" "n")     { Install-Ghostty } }

    # ─────────────────────────────────────────────────────────────────────
    # Phase 6: Salesforce Git Access
    # ─────────────────────────────────────────────────────────────────────
    Run-GitAccessPhase

    # ─────────────────────────────────────────────────────────────────────
    # Phase 7: Health Check & Next Steps
    # ─────────────────────────────────────────────────────────────────────
    Write-Host ""
    Write-Host "  Phase 7: Verification" -ForegroundColor White
    Write-Host "  ════════════════════════════════════════════════"

    Run-HealthCheck

    Write-Host ""
    Write-Host "  Setup complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Next Steps:" -ForegroundColor White
    Write-Host ""
    Write-Host "    1. Authenticate Claude Code:"
    Write-Host "         claude"
    Write-Host ""
    Write-Host "    2. Authenticate GitHub CLI (optional):"
    Write-Host "         gh auth login"
    Write-Host ""
    Write-Host "    3. Authenticate Salesforce CLI (optional):"
    Write-Host "         sf org login web"
    Write-Host ""
    Write-Host "    4. Salesforce git access docs:"
    Write-Host "         docs/git-soma-setup.md"
    Write-Host "         docs/git-emu-setup.md"
    Write-Host ""
    Write-Host "    5. Restart your terminal to pick up PATH changes"
    Write-Host ""
}

Main
