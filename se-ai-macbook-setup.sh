#!/bin/bash
# ============================================================================
# SE AI MacBook Setup
# Installs all tools needed for AI-assisted software engineering on macOS
#
# Usage:
#   curl -sSL <raw-url>/install.sh | bash
#
# Or run locally:
#   chmod +x install.sh
#   ./install.sh                          # full interactive setup
#   ./install.sh cursor node git          # check/install specific components only
#   ./install.sh --help                   # list available components
#
# ============================================================================
set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

MIN_PYTHON_MAJOR=3
MIN_PYTHON_MINOR=10
MIN_NODE_VERSION=18
MIN_GIT_VERSION=2

# ============================================================================
# COLORS & OUTPUT HELPERS
# ============================================================================

if [[ -t 1 ]] && [[ "${TERM:-}" != "dumb" ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    DIM='\033[2m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' BOLD='' DIM='' NC=''
fi

print_banner() {
    echo -e "${CYAN}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════╗
║              SE AI MacBook Setup                                 ║
║       AI-Assisted Software Engineering Toolkit                   ║
╚══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

print_step()    { echo -e "${BLUE}▶${NC} $1"; }
print_success() { echo -e "  ${GREEN}✓${NC} $1"; }
print_warning() { echo -e "  ${YELLOW}⚠${NC} $1"; }
print_error()   { echo -e "  ${RED}✗${NC} $1"; }
print_info()    { echo -e "  ${CYAN}ℹ${NC} $1"; }
explain()       { echo -e "  ${DIM}💡 $1${NC}"; }

confirm() {
    local prompt="$1"
    local default="${2:-y}"
    if [[ "$default" == "y" ]]; then
        read -rp "$(echo -e "  ${YELLOW}?${NC} $prompt [Y/n]: ")" response
        [[ -z "$response" || "$response" =~ ^[Yy] ]]
    else
        read -rp "$(echo -e "  ${YELLOW}?${NC} $prompt [y/N]: ")" response
        [[ "$response" =~ ^[Yy] ]]
    fi
}

# ============================================================================
# OS & ARCH DETECTION
# ============================================================================

detect_arch() {
    case "$(uname -m)" in
        arm64|aarch64) echo "arm64" ;;
        x86_64)        echo "x86_64" ;;
        *)             echo "unknown" ;;
    esac
}

detect_rosetta() {
    if [[ "$(detect_arch)" == "arm64" ]]; then
        if [[ "$(sysctl -n sysctl.proc_translated 2>/dev/null)" == "1" ]]; then
            return 0
        fi
    fi
    return 1
}

# Ensure macOS
if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "This script is for macOS only."
    exit 1
fi

# ============================================================================
# HOMEBREW
# ============================================================================

check_homebrew() {
    print_step "Checking Homebrew..."
    explain "Package manager for macOS — the foundation for all other installs."
    if command -v brew &>/dev/null; then
        print_success "Homebrew $(brew --version | head -1)"
        return 0
    fi
    print_warning "Homebrew not found"
    return 1
}

install_homebrew() {
    print_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f "/usr/local/bin/brew" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    print_success "Homebrew installed"
}

# ============================================================================
# XCODE COMMAND LINE TOOLS (git, clang, make, etc.)
# ============================================================================

check_xcode_tools() {
    print_step "Checking Xcode Command Line Tools..."
    explain "Provides git, clang, make, and other essential dev tools."
    if xcode-select -p &>/dev/null; then
        print_success "Xcode CLT: $(xcode-select -p)"
        return 0
    fi
    print_warning "Xcode Command Line Tools not found"
    return 1
}

install_xcode_tools() {
    print_info "Installing Xcode Command Line Tools..."
    xcode-select --install
    # Wait for user to finish the GUI installer before continuing
    until xcode-select -p &>/dev/null; do
        sleep 5
    done
    print_success "Xcode Command Line Tools installed"
}

# ============================================================================
# GIT
# ============================================================================

check_git() {
    print_step "Checking Git ${MIN_GIT_VERSION}+..."
    explain "Version control — required by Claude Code, npm packages, and most AI tools."
    if ! command -v git &>/dev/null; then
        print_warning "Git not found"
        return 1
    fi
    local version major
    version=$(git --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    major=${version%%.*}
    if [[ "$major" -ge "$MIN_GIT_VERSION" ]]; then
        print_success "Git $version"
        return 0
    fi
    print_warning "Git $version found, but ${MIN_GIT_VERSION}+ required"
    return 1
}

install_git() {
    print_info "Installing Git via Homebrew..."
    brew install git
    print_success "Git installed"
}

# ============================================================================
# PYTHON
# ============================================================================

check_python() {
    print_step "Checking Python ${MIN_PYTHON_MAJOR}.${MIN_PYTHON_MINOR}+..."
    explain "Required for AI/ML libraries, Claude hooks, and scripting."
    if ! command -v python3 &>/dev/null; then
        print_warning "Python 3 not found"
        return 1
    fi
    local version major minor
    version=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>/dev/null || echo "0.0")
    major=${version%%.*}
    minor=${version#*.}
    if [[ "$major" -gt "$MIN_PYTHON_MAJOR" ]] || \
       [[ "$major" -eq "$MIN_PYTHON_MAJOR" && "$minor" -ge "$MIN_PYTHON_MINOR" ]]; then
        print_success "Python $version ($(which python3))"
        return 0
    fi
    print_warning "Python $version found, but ${MIN_PYTHON_MAJOR}.${MIN_PYTHON_MINOR}+ required"
    return 1
}

install_python() {
    print_info "Installing Python 3.12 via Homebrew..."
    brew install python@3.12
    print_success "Python 3.12 installed"
}

check_ssl_certs() {
    print_step "Checking Python SSL certificates..."
    if python3 -c "import urllib.request; urllib.request.urlopen('https://api.github.com', timeout=5)" 2>/dev/null; then
        print_success "SSL certificates OK"
        return 0
    fi
    if python3 -c "import certifi" 2>/dev/null; then
        print_warning "System SSL certs missing, but certifi found (will be used automatically)"
        return 0
    fi
    print_warning "SSL certificate verification failed"
    if confirm "Install certifi to fix SSL?"; then
        pip3 install --quiet certifi && print_success "certifi installed"
    fi
}

# ============================================================================
# UV (fast Python package manager)
# ============================================================================

check_uv() {
    print_step "Checking uv (Python package manager)..."
    explain "A fast drop-in replacement for pip/venv — great for AI project environments."
    if command -v uv &>/dev/null; then
        print_success "uv $(uv --version)"
        return 0
    fi
    print_warning "uv not found"
    return 1
}

install_uv() {
    print_info "Installing uv..."
    brew install uv
    print_success "uv installed"
}

# ============================================================================
# NODE.JS & NPM
# ============================================================================

check_node() {
    print_step "Checking Node.js ${MIN_NODE_VERSION}+..."
    explain "Required for Claude Code CLI and many AI tool integrations."
    if ! command -v node &>/dev/null; then
        print_warning "Node.js not found"
        return 1
    fi
    local version major
    version=$(node --version | sed 's/^v//')
    major=${version%%.*}
    if [[ "$major" -ge "$MIN_NODE_VERSION" ]]; then
        print_success "Node.js $version  |  npm $(npm --version)"
        return 0
    fi
    print_warning "Node.js $version found, but ${MIN_NODE_VERSION}+ required"
    return 1
}

install_node() {
    print_info "Installing Node.js via Homebrew..."
    brew install node
    print_success "Node.js installed"
}

# ============================================================================
# CLAUDE CODE
# ============================================================================

check_claude_code() {
    print_step "Checking Claude Code..."
    explain "Anthropic's AI coding assistant CLI."
    if command -v claude &>/dev/null; then
        print_success "Claude Code $(claude --version 2>/dev/null || echo '(version unknown)')"
        return 0
    fi
    print_warning "Claude Code not installed"
    return 1
}

install_claude_code() {
    print_info "Installing Claude Code globally via npm..."
    npm install -g @anthropic-ai/claude-code
    print_success "Claude Code installed"
    print_info "Run 'claude' to authenticate and start your first session"
}

# ============================================================================
# GITHUB CLI
# ============================================================================

check_gh() {
    print_step "Checking GitHub CLI..."
    explain "Interact with GitHub repos, PRs, issues, and Actions from the terminal."
    if command -v gh &>/dev/null; then
        print_success "GitHub CLI $(gh --version | head -1)"
        return 0
    fi
    print_warning "GitHub CLI not found"
    return 1
}

install_gh() {
    print_info "Installing GitHub CLI via Homebrew..."
    brew install gh
    print_success "GitHub CLI installed"
}

# ============================================================================
# HEROKU CLI
# ============================================================================

check_heroku() {
    print_step "Checking Heroku CLI..."
    explain "Deploy and manage apps on Heroku from the terminal."
    if command -v heroku &>/dev/null; then
        print_success "Heroku CLI $(heroku --version 2>/dev/null | head -1 || echo '(version unknown)')"
        return 0
    fi
    print_warning "Heroku CLI not found"
    return 1
}

install_heroku() {
    print_info "Installing Heroku CLI via Homebrew..."
    brew tap heroku/brew && brew install heroku
    print_success "Heroku CLI installed"
    print_info "Run 'heroku login' to authenticate"
}

# ============================================================================
# CURL
# ============================================================================

check_curl() {
    print_step "Checking curl..."
    if command -v curl &>/dev/null; then
        print_success "curl $(curl --version | head -1 | awk '{print $2}')"
        return 0
    fi
    print_error "curl not found — this is unusual on macOS"
    return 1
}

# ============================================================================
# OPTIONAL: jq
# ============================================================================

check_jq() {
    print_step "Checking jq (JSON processor)..."
    explain "Useful for parsing AI API responses and JSON configs in scripts."
    if command -v jq &>/dev/null; then
        print_success "jq $(jq --version)"
        return 0
    fi
    print_warning "jq not found"
    return 1
}

install_jq() {
    brew install jq
    print_success "jq installed"
}

# ============================================================================
# OPTIONAL: VS Code
# ============================================================================

check_vscode() {
    print_step "Checking VS Code..."
    explain "Popular editor with Claude Code extension support."
    if command -v code &>/dev/null || [[ -d "/Applications/Visual Studio Code.app" ]] || [[ -d "$HOME/Applications/Visual Studio Code.app" ]]; then
        print_success "VS Code found"
        return 0
    fi
    print_warning "VS Code not found"
    return 1
}

install_vscode() {
    print_info "Installing VS Code via Homebrew..."
    brew install --cask visual-studio-code
    print_success "VS Code installed"
}

# ============================================================================
# OPTIONAL: Cursor editor
# ============================================================================

check_cursor() {
    print_step "Checking Cursor..."
    explain "AI-first code editor — supports Claude Code and Salesforce extensions."
    if command -v cursor &>/dev/null || [[ -d "/Applications/Cursor.app" ]]; then
        print_success "Cursor found"
        return 0
    fi
    print_warning "Cursor not found"
    return 1
}

install_cursor() {
    print_info "Installing Cursor via Homebrew..."
    brew install --cask cursor
    print_success "Cursor installed"
}

# ============================================================================
# OPTIONAL: Salesforce Extension Pack for Cursor
# ============================================================================

check_sf_extension_cursor() {
    print_step "Checking Salesforce Extension Pack in Cursor..."
    explain "Provides Apex, SOQL, LWC, and org management support inside Cursor."
    if ! command -v cursor &>/dev/null; then
        print_warning "cursor CLI not in PATH — open Cursor and run 'Install Shell Command' first"
        return 1
    fi
    if cursor --list-extensions 2>/dev/null | grep -qi "salesforce.salesforcedx-vscode"; then
        print_success "Salesforce Extension Pack found in Cursor"
        return 0
    fi
    print_warning "Salesforce Extension Pack not installed in Cursor"
    return 1
}

install_sf_extension_cursor() {
    print_info "Installing Salesforce Extension Pack in Cursor..."
    cursor --install-extension salesforce.salesforcedx-vscode
    print_success "Salesforce Extension Pack installed in Cursor"
}

# ============================================================================
# OPTIONAL: Ghostty terminal
# ============================================================================

check_ghostty() {
    print_step "Checking Ghostty terminal..."
    explain "A fast, modern terminal — recommended for the best Claude Code experience."
    if [[ -d "/Applications/Ghostty.app" ]] || command -v ghostty &>/dev/null; then
        print_success "Ghostty found"
        return 0
    fi
    print_warning "Ghostty not found"
    return 1
}

install_ghostty() {
    print_info "Installing Ghostty via Homebrew..."
    brew install --cask ghostty
    print_success "Ghostty installed"
}

# ============================================================================
# OPTIONAL: Java (for tools that need JVM)
# ============================================================================

check_java() {
    print_step "Checking Java 11+..."
    explain "Needed by some AI-adjacent tools and code analysis engines."
    local java_bin=""
    for candidate in \
        "/opt/homebrew/opt/openjdk@21/bin/java" \
        "/opt/homebrew/opt/openjdk@17/bin/java" \
        "/opt/homebrew/opt/openjdk@11/bin/java" \
        "/opt/homebrew/opt/openjdk/bin/java" \
        "/usr/bin/java"
    do
        if [[ -x "$candidate" ]]; then java_bin="$candidate"; break; fi
    done
    [[ -z "$java_bin" ]] && command -v java &>/dev/null && java_bin="$(which java)"

    if [[ -z "$java_bin" ]]; then
        print_warning "Java not found (optional)"
        return 1
    fi
    local version major
    version=$("$java_bin" -version 2>&1 | head -1 | grep -oE '[0-9]+(\.[0-9]+)*' | head -1)
    major=${version%%.*}
    if [[ "$major" -ge 11 ]]; then
        print_success "Java $version"
        return 0
    fi
    print_warning "Java $version found, but 11+ recommended"
    return 1
}

install_java() {
    print_info "Installing OpenJDK 21 via Homebrew..."
    brew install openjdk@21
    print_success "OpenJDK 21 installed"
    print_info "You may need to add it to PATH: export PATH=\"/opt/homebrew/opt/openjdk@21/bin:\$PATH\""
}

# ============================================================================
# SALESFORCE CLI
# ============================================================================

check_sf() {
    print_step "Checking Salesforce CLI..."
    explain "Official Salesforce CLI (sf) — deploy metadata, run Apex, manage orgs."
    if command -v sf &>/dev/null; then
        print_success "Salesforce CLI $(sf --version 2>/dev/null | head -1 || echo '(version unknown)')"
        return 0
    fi
    print_warning "Salesforce CLI not installed"
    return 1
}

install_sf() {
    print_info "Installing Salesforce CLI globally via npm..."
    npm install -g @salesforce/cli
    print_success "Salesforce CLI installed"
    print_info "Run 'sf org login web' to authenticate to a Salesforce org"
}

# ============================================================================
# SALESFORCE GIT ACCESS (Phase 6)
# ============================================================================

check_git_credential_helper() {
    # Returns 0 if osxkeychain is among the configured helpers (handles multiple values)
    git config --global --get-all credential.helper 2>/dev/null | grep -q "^osxkeychain$"
}

setup_git_credential_helper() {
    if ! check_git_credential_helper; then
        # Use --add so we don't clobber any existing helpers (e.g. manager, store)
        git config --global --add credential.helper osxkeychain
        print_success "git credential.helper osxkeychain added"
    else
        print_success "git credential.helper already includes osxkeychain"
    fi
}

check_soma_reachable() {
    # Returns 0 if we get an Okta/SSO redirect (expected), 1 if unreachable
    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 8 \
        "https://git.soma.salesforce.com" 2>/dev/null || echo "000")
    # 200 (logged in), 302/301 (Okta redirect) all mean reachable
    if [[ "$http_code" == "200" || "$http_code" == "301" || "$http_code" == "302" ]]; then
        return 0
    fi
    return 1
}

check_soma_authenticated() {
    # 1. Keychain check — security returns non-zero if no entry; use if to stay set -e safe
    if ! security find-internet-password -s git.soma.salesforce.com &>/dev/null; then
        return 1
    fi
    # 2. Probe sentinel repo; GIT_TERMINAL_PROMPT=0 prevents interactive credential prompts
    if ! GIT_TERMINAL_PROMPT=0 git ls-remote --exit-code \
            "https://git.soma.salesforce.com/john-hill/se-ai-macbook-setup.git" \
            HEAD &>/dev/null; then
        return 1  # Keychain entry exists but PAT is expired/revoked
    fi
    return 0
}

check_emu_authenticated() {
    local emu_account
    # Wrap security in { || true; } so pipefail doesn't fire when there's no github.com entry
    emu_account=$({ security find-internet-password -s github.com 2>/dev/null || true; } \
        | { grep "acct" || true; } \
        | { grep "_sfemu" || true; } \
        | sed 's/.*= "//' | tr -d '"' | head -1)
    if [[ -z "$emu_account" ]]; then
        return 1  # No _sfemu keychain entry
    fi
    if ! GIT_TERMINAL_PROMPT=0 git ls-remote --exit-code \
            "https://github.com/Authoring-Agent/agentforce-adlc.git" \
            HEAD &>/dev/null; then
        return 1  # _sfemu entry exists but PAT is expired/revoked
    fi
    return 0
}

get_emu_account() {
    # Returns the _sfemu username from keychain, or empty string — never fails
    { security find-internet-password -s github.com 2>/dev/null || true; } \
        | { grep "acct" || true; } \
        | { grep "_sfemu" || true; } \
        | sed 's/.*= "//' | tr -d '"' | head -1
}

show_soma_steps() {
    echo ""
    echo -e "${BOLD}  git.soma Setup Guide${NC}"
    echo "  ────────────────────────────────────────"
    echo ""
    print_info "Step 1: Request AD group access via IIQ"
    print_info "  1. Go to salesforce.okta.com → search for IdentityIQ (IIQ)"
    print_info "  2. Click Manage User Access → select yourself → Next"
    print_info "  3. Search for 'Technology-RnD-Access' and submit with a justification"
    print_info "  Contractors: also request 'Aloha - BPO GitSoma'"
    echo ""
    print_info "Step 2: Manager approval"
    print_info "  An approval email is sent to your manager automatically."
    print_info "  Give them a heads-up — they approve via email."
    echo ""
    print_info "Step 3: Wait for access to propagate (~4 hours, up to 24–48 hours)"
    echo ""
    print_info "Step 4: First login — go to git.soma.salesforce.com"
    print_info "  Your account is created automatically on first Okta SSO login."
    echo ""
    print_info "Step 5: Generate a Personal Access Token"
    print_info "  Profile → Settings → Access Tokens"
    print_info "  Required scopes: read_repository, write_repository"
    echo ""
    print_info "Step 6: Cache credentials in macOS Keychain"
    print_info "  Clone any repo via HTTPS — macOS will prompt for your username and PAT."
    print_info "  git clone https://git.soma.salesforce.com/<org>/<repo>.git"
    print_info "  Use your PAT as the password — Keychain will cache it."
    echo ""
    print_info "Help: Slack #scm-git-collab or #help-techforce"
}

show_emu_steps() {
    echo ""
    echo -e "${BOLD}  git EMU Setup Guide${NC}"
    echo "  ────────────────────────────────────────"
    echo ""
    print_info "Step 1: Create your EMU account"
    print_info "  1. Go to salesforce.okta.com"
    print_info "  2. Find and click 'GitHub Salesforce - EMU'"
    print_info "  Your username will end in _sfemu (e.g. jsmith_sfemu)"
    echo ""
    print_info "Step 2: Request org access via IIQ"
    print_info "  1. Open IdentityIQ (IIQ) in Okta"
    print_info "  2. Search for 'GHEC_<org-name>_Users' (e.g. GHEC_salesforce-ux-emu_Users)"
    print_info "  3. Not sure which group? Use /prodeng github-access in Slack"
    print_info "  4. Submit with a business justification"
    echo ""
    print_info "Step 3: Manager approval + wait 20 min to 4+ hours"
    print_info "  Verify by visiting the org URL on github.com."
    echo ""
    print_info "Step 4: Generate a Personal Access Token"
    print_info "  Log in to github.com as your _sfemu account"
    print_info "  Settings → Developer settings → Personal access tokens → Tokens (classic)"
    print_info "  Required scopes: repo, read:org"
    echo ""
    print_info "Step 5: Cache credentials in macOS Keychain"
    print_info "  Clone any EMU repo via HTTPS — macOS will prompt for credentials."
    print_info "  git clone https://github.com/<salesforce-emu-org>/<repo>.git"
    print_info "  Use your _sfemu username and PAT as the password."
    echo ""
    print_info "Help: /prodeng github-access in Slack"
}

setup_git_soma() {
    echo ""
    echo -e "${BOLD}  git.soma (GitHub Enterprise)${NC}"
    echo "  ────────────────────────────────────────"
    explain "Internal Salesforce GitHub. Full guide: docs/git-soma-setup.md"
    echo ""

    # Pre-check: keychain + live auth probe
    print_step "Checking git.soma authentication..."
    if check_soma_authenticated; then
        print_success "Already authenticated to git.soma (keychain PAT verified)"
        return 0
    fi

    # Distinguish: reachable but no valid creds vs. not reachable at all
    if check_soma_reachable; then
        print_success "git.soma.salesforce.com is reachable"
        if security find-internet-password -s git.soma.salesforce.com &>/dev/null; then
            print_warning "Keychain has a git.soma entry but authentication failed — PAT may be expired"
            print_info "Regenerate your PAT: git.soma → Profile → Settings → Access Tokens"
            return 0
        fi
    else
        print_warning "git.soma.salesforce.com is not reachable"
        print_info "This usually means you need to request AD group access first."
    fi

    # Step 1: AD group access
    echo ""
    if confirm "Have you requested 'Technology-RnD-Access' in IdentityIQ (IIQ)?"; then
        print_success "AD group access requested"

        # Step 2: Manager approval
        if confirm "Has your manager approved the request?"; then
            print_success "Manager approved"

            # Step 3: Can they log in?
            if confirm "Can you successfully log in to git.soma.salesforce.com?"; then
                print_success "git.soma login confirmed"
            else
                print_info "Access can take 4–48 hours after approval."
                print_info "Try again later. See: docs/git-soma-setup.md"
            fi
        else
            print_info "Follow up with your manager — they'll receive an approval email."
            print_info "Once approved, access propagates in ~4 hours."
        fi
    else
        echo ""
        print_info "To request access:"
        print_info "  1. Go to salesforce.okta.com → IdentityIQ (IIQ)"
        print_info "  2. Click Manage User Access → select yourself → Next"
        print_info "  3. Search for 'Technology-RnD-Access' and submit with justification"
        print_info "  Contractors: also request 'Aloha - BPO GitSoma'"
        print_info "  Full guide: docs/git-soma-setup.md"
    fi

    # PAT setup
    echo ""
    if confirm "Have you generated a Personal Access Token on git.soma?"; then
        print_step "Verifying git.soma access with your PAT..."
        if GIT_TERMINAL_PROMPT=0 git ls-remote --exit-code \
                "https://git.soma.salesforce.com/john-hill/se-ai-macbook-setup.git" \
                HEAD &>/dev/null; then
            print_success "git.soma access verified — PAT works and is cached in Keychain"
        else
            print_warning "Could not authenticate to git.soma — PAT may not be stored yet"
            print_info "Clone any git.soma repo via HTTPS to trigger the Keychain prompt:"
            print_info "  git clone https://git.soma.salesforce.com/<org>/<repo>.git"
            print_info "  Use your PAT as the password — macOS Keychain will cache it."
        fi
    else
        print_info "To generate a token:"
        print_info "  git.soma → Profile → Settings → Access Tokens"
        print_info "  Then clone any repo via HTTPS — git will prompt for credentials."
    fi
}

setup_git_emu() {
    echo ""
    echo -e "${BOLD}  git EMU (GitHub Enterprise Managed Users)${NC}"
    echo "  ────────────────────────────────────────"
    explain "Salesforce orgs on github.com with _sfemu accounts. Full guide: docs/git-emu-setup.md"
    echo ""

    # Pre-check: keychain _sfemu entry + live auth probe
    print_step "Checking git EMU authentication..."
    if check_emu_authenticated; then
        local emu_acct
        emu_acct=$(get_emu_account)
        print_success "Already authenticated to GitHub EMU${emu_acct:+ as $emu_acct} (keychain PAT verified)"
        return 0
    fi

    # Distinguish: _sfemu keychain entry exists but auth failed vs. no entry at all
    local emu_acct
    emu_acct=$(get_emu_account)
    if [[ -n "$emu_acct" ]]; then
        print_warning "Keychain has an EMU entry ($emu_acct) but authentication failed — PAT may be expired"
        print_info "Regenerate your PAT: github.com (as $emu_acct) → Settings → Developer settings"
        print_info "  → Personal access tokens → Tokens (classic) → Generate new token"
        print_info "  Minimum scopes: repo, read:org"
        return 0
    fi

    # Step 1: EMU account created?
    if confirm "Have you clicked the 'GitHub Salesforce - EMU' tile in Okta to create your EMU account?"; then
        print_success "EMU account exists"

        # Step 2: Org access
        if confirm "Have you requested access to the specific GitHub org you need via IIQ?"; then
            print_success "Org access requested"
            print_info "Org access can take 20 min to 4+ hours after manager approval."
            print_info "Check access by visiting the org URL on github.com."
        else
            echo ""
            print_info "To request org access:"
            print_info "  1. Open IdentityIQ (IIQ) in Okta"
            print_info "  2. Search for 'GHEC_<org-name>_Users' (e.g. GHEC_salesforce-ux-emu_Users)"
            print_info "  3. Not sure which group? Use /prodeng github-access in Slack"
            print_info "  Full guide: docs/git-emu-setup.md"
        fi
    else
        echo ""
        print_info "To create your EMU account:"
        print_info "  1. Go to salesforce.okta.com"
        print_info "  2. Find and click 'GitHub Salesforce - EMU'"
        print_info "  Your username will end in _sfemu (e.g. jsmith_sfemu)"
        print_info "  Full guide: docs/git-emu-setup.md"
    fi

    # PAT setup
    echo ""
    if confirm "Have you generated a Personal Access Token for your _sfemu account on github.com?"; then
        print_step "Verifying git EMU access with your PAT..."
        if GIT_TERMINAL_PROMPT=0 git ls-remote --exit-code \
                "https://github.com/Authoring-Agent/agentforce-adlc.git" \
                HEAD &>/dev/null; then
            print_success "git EMU access verified — PAT works and is cached in Keychain"
        else
            print_warning "Could not authenticate to GitHub EMU — PAT may not be stored yet"
            print_info "Clone any EMU repo via HTTPS to trigger the Keychain prompt:"
            print_info "  git clone https://github.com/<org>/<repo>.git"
            print_info "  Use your _sfemu username and PAT as the password."
            print_info "  macOS Keychain will cache it for future use."
        fi
    else
        print_info "To generate a token:"
        print_info "  github.com (logged in as _sfemu) → Settings → Developer settings"
        print_info "  → Personal access tokens → Tokens (classic) → Generate new token"
        print_info "  Minimum scopes: repo, read:org"
    fi
}

run_git_access_phase() {
    echo ""
    echo -e "${BOLD}Phase 6: Salesforce Git Access (Optional)${NC}"
    echo "════════════════════════════════════════════════"
    explain "Sets up credentials for git.soma and GitHub EMU."
    echo ""

    # Pre-flight status check — runs silently, shows a summary
    print_step "Checking existing git access..."
    local soma_ok=false emu_ok=false
    check_soma_authenticated && soma_ok=true
    check_emu_authenticated  && emu_ok=true

    if $soma_ok; then
        print_success "git.soma       — authenticated"
    else
        print_warning "git.soma       — not yet configured"
    fi
    if $emu_ok; then
        print_success "git EMU        — authenticated"
    else
        print_warning "git EMU        — not yet configured"
    fi

    # If both are already good, nothing to do
    if $soma_ok && $emu_ok; then
        print_success "Both git environments already configured — nothing to do"
        return 0
    fi

    echo ""
    if ! confirm "Set up Salesforce git access now?" "n"; then
        print_info "Skipped. Run the script again or see docs/git-soma-setup.md and docs/git-emu-setup.md"
        return 0
    fi

    # Always auto-configure credential helper
    print_step "Configuring git credential helper..."
    setup_git_credential_helper

    # git.soma — skip prompt if already authenticated
    echo ""
    if $soma_ok; then
        print_success "git.soma already authenticated — skipping"
    elif confirm "Show git.soma setup steps?"; then
        show_soma_steps
    else
        print_info "Skipped — see docs/git-soma-setup.md for setup steps"
    fi

    # git EMU — skip prompt if already authenticated
    echo ""
    if $emu_ok; then
        print_success "git EMU already authenticated — skipping"
    elif confirm "Show git EMU setup steps?"; then
        show_emu_steps
    else
        print_info "Skipped — see docs/git-emu-setup.md for setup steps"
    fi
}

# ============================================================================
# SHELL CONFIG HELPER
# ============================================================================

detect_shell_rc() {
    case "${SHELL:-}" in
        */zsh)  echo "$HOME/.zshrc" ;;
        */bash) echo "$HOME/.bash_profile" ;;
        *)      echo "$HOME/.profile" ;;
    esac
}

# ============================================================================
# HEALTH CHECK
# ============================================================================

run_health_check() {
    # Optional args: canonical component names to filter by (show all if none given)
    local filter=("$@")

    echo ""
    echo -e "${BOLD}Environment Status:${NC}"
    echo "────────────────────────────────────────────────"

    local tools=(
        "brew:brew --version | head -1"
        "git:git --version"
        "python3:python3 --version"
        "uv:uv --version"
        "node:node --version"
        "npm:npm --version"
        "claude:claude --version 2>/dev/null || echo '(run claude to authenticate)'"
        "sf:sf --version 2>/dev/null | head -1"
        "heroku:heroku --version 2>/dev/null | head -1"
        "gh:gh --version | head -1"
        "curl:curl --version | head -1 | awk '{print \$1\" \"\$2}'"
        "jq:jq --version"
        "code:code --version | head -1"
        "cursor:cursor --version 2>/dev/null | head -1"
        "java:java -version 2>&1 | head -1"
    )

    for entry in "${tools[@]}"; do
        local name="${entry%%:*}"
        local cmd="${entry#*:}"
        # When a filter is active, skip tools not in the requested set
        if [[ ${#filter[@]} -gt 0 ]]; then
            local canonical
            canonical=$(tool_to_component "$name")
            in_array "$canonical" "${filter[@]}" || continue
        fi
        if command -v "$name" &>/dev/null; then
            local ver
            ver=$(eval "$cmd" 2>/dev/null || echo "found")
            printf "  ${GREEN}✓${NC}  %-20s %s\n" "$name" "$ver"
        else
            printf "  ${YELLOW}○${NC}  %-20s %s\n" "$name" "not installed"
        fi
    done

    # git credential helper & git.soma — only in full mode (no filter)
    if [[ ${#filter[@]} -eq 0 ]]; then
        local cred_helpers
        cred_helpers=$(git config --global --get-all credential.helper 2>/dev/null | tr '\n' ' ' | sed 's/ $//')
        if [[ -z "$cred_helpers" ]]; then cred_helpers="not set"; fi
        if check_git_credential_helper; then
            printf "  ${GREEN}✓${NC}  %-20s %s\n" "credential.helper" "$cred_helpers"
        else
            printf "  ${YELLOW}○${NC}  %-20s %s\n" "credential.helper" "$cred_helpers"
        fi

        if check_soma_reachable; then
            printf "  ${GREEN}✓${NC}  %-20s %s\n" "git.soma" "reachable"
        else
            printf "  ${YELLOW}○${NC}  %-20s %s\n" "git.soma" "not reachable (needs IIQ access)"
        fi
    fi

    echo "────────────────────────────────────────────────"
}

# ============================================================================
# TARGETED MODE — helpers and dispatcher
# ============================================================================

# Map health-check command name to canonical component name
tool_to_component() {
    case "$1" in
        python3) echo "python" ;;
        npm)     echo "node" ;;
        code)    echo "vscode" ;;
        *)       echo "$1" ;;
    esac
}

# All canonical component names in dependency-safe order
ALL_COMPONENTS=(curl xcode brew git python node uv claude sf heroku gh jq java vscode cursor sf-extension-cursor ghostty)

# Bash-3-compatible array membership test
in_array() {
    local needle="$1"; shift
    local elem
    for elem in "$@"; do [[ "$elem" == "$needle" ]] && return 0; done
    return 1
}

# Map user-friendly aliases to canonical component names
normalize_component() {
    case "$1" in
        homebrew)                                   echo "brew" ;;
        xcode-clt|xcode-tools)                      echo "xcode" ;;
        python3)                                    echo "python" ;;
        nodejs)                                     echo "node" ;;
        claude-code)                                echo "claude" ;;
        salesforce|salesforce-cli)                  echo "sf" ;;
        github-cli|github)                          echo "gh" ;;
        heroku-cli)                                 echo "heroku" ;;
        vs-code|code)                               echo "vscode" ;;
        sf-extension|salesforce-extension-cursor|sf-ext) echo "sf-extension-cursor" ;;
        *)                                          echo "$1" ;;
    esac
}

# Return space-separated direct dependencies for a canonical component
deps_of() {
    case "$1" in
        xcode)               echo "curl" ;;
        brew)                echo "xcode" ;;
        git|python|uv|gh|heroku|jq|java|vscode|cursor|ghostty|node) echo "brew" ;;
        claude|sf)           echo "node" ;;
        sf-extension-cursor) echo "cursor" ;;
        *)                   echo "" ;;
    esac
}

# Human-readable label for install prompts
label_of() {
    case "$1" in
        xcode)               echo "Xcode Command Line Tools" ;;
        brew)                echo "Homebrew" ;;
        git)                 echo "Git" ;;
        python)              echo "Python 3.12" ;;
        node)                echo "Node.js" ;;
        uv)                  echo "uv (Python package manager)" ;;
        claude)              echo "Claude Code (npm)" ;;
        sf)                  echo "Salesforce CLI (npm)" ;;
        heroku)              echo "Heroku CLI" ;;
        gh)                  echo "GitHub CLI" ;;
        jq)                  echo "jq (JSON processor)" ;;
        java)                echo "Java 21 (OpenJDK)" ;;
        vscode)              echo "VS Code" ;;
        cursor)              echo "Cursor" ;;
        sf-extension-cursor) echo "Salesforce Extension Pack for Cursor" ;;
        ghostty)             echo "Ghostty terminal" ;;
        *)                   echo "$1" ;;
    esac
}

# Dispatch check to the appropriate check_* function
check_component() {
    case "$1" in
        curl)                check_curl ;;
        xcode)               check_xcode_tools ;;
        brew)                check_homebrew ;;
        git)                 check_git ;;
        python)              check_python ;;
        node)                check_node ;;
        uv)                  check_uv ;;
        claude)              check_claude_code ;;
        sf)                  check_sf ;;
        heroku)              check_heroku ;;
        gh)                  check_gh ;;
        jq)                  check_jq ;;
        java)                check_java ;;
        vscode)              check_vscode ;;
        cursor)              check_cursor ;;
        sf-extension-cursor) check_sf_extension_cursor ;;
        ghostty)             check_ghostty ;;
        *) print_error "Unknown component: $1"; return 1 ;;
    esac
}

# Dispatch install to the appropriate install_* function
install_component() {
    case "$1" in
        curl)                return 0 ;;  # no installer; script errors if curl missing
        xcode)               install_xcode_tools ;;
        brew)                install_homebrew ;;
        git)                 install_git ;;
        python)              install_python ;;
        node)                install_node ;;
        uv)                  install_uv ;;
        claude)              install_claude_code ;;
        sf)                  install_sf ;;
        heroku)              install_heroku ;;
        gh)                  install_gh ;;
        jq)                  install_jq ;;
        java)                install_java ;;
        vscode)              install_vscode ;;
        cursor)              install_cursor ;;
        sf-extension-cursor) install_sf_extension_cursor ;;
        ghostty)             install_ghostty ;;
    esac
}

# Global set populated by add_with_deps
NEEDED=()

# Recursively expand a component and its dependencies into NEEDED
add_with_deps() {
    local comp="$1"
    in_array "$comp" "${NEEDED[@]:-}" && return
    local dep
    for dep in $(deps_of "$comp"); do
        add_with_deps "$dep"
    done
    NEEDED+=("$comp")
}

run_targeted() {
    if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
        echo "Usage: $0 [component ...]"
        echo ""
        echo "  Checks (and optionally installs) only the specified components,"
        echo "  automatically including any required dependencies."
        echo ""
        echo "  Run with no arguments to step through the full interactive setup."
        echo ""
        echo "  Components:"
        echo "    curl  xcode  brew  git  python  node  uv  claude  sf  heroku"
        echo "    gh    jq     java  vscode  cursor  sf-extension-cursor  ghostty"
        echo ""
        echo "  Aliases:"
        echo "    homebrew, xcode-clt, python3, nodejs, claude-code,"
        echo "    salesforce, salesforce-cli, github-cli, heroku-cli,"
        echo "    vs-code, sf-extension, sf-ext"
        echo ""
        return 0
    fi

    local arch
    arch=$(detect_arch)
    echo -e "${BOLD}System Info:${NC}"
    echo "  macOS $(sw_vers -productVersion)  |  arch: $arch"
    echo ""

    # Normalize and validate each argument
    local requested=()
    local arg canonical
    for arg in "$@"; do
        canonical=$(normalize_component "$arg")
        if ! in_array "$canonical" "${ALL_COMPONENTS[@]}"; then
            print_error "Unknown component: '$arg'"
            echo "  Run '$0 --help' for the list of valid components."
            exit 1
        fi
        requested+=("$canonical")
    done

    # Expand all deps into NEEDED (global, reset each call)
    NEEDED=()
    local comp
    for comp in "${requested[@]}"; do
        add_with_deps "$comp"
    done

    # Report what will run, flagging auto-added dependencies
    echo -e "${BOLD}Checking:${NC} ${requested[*]}"
    local auto_added=()
    for comp in "${NEEDED[@]}"; do
        in_array "$comp" "${requested[@]}" || auto_added+=("$comp")
    done
    if [[ ${#auto_added[@]} -gt 0 ]]; then
        echo -e "${DIM}  + dependencies: ${auto_added[*]}${NC}"
    fi
    echo "════════════════════════════════════════════════"

    # Process components in canonical (dependency-safe) order
    for comp in "${ALL_COMPONENTS[@]}"; do
        in_array "$comp" "${NEEDED[@]}" || continue
        if [[ "$comp" == "curl" ]]; then
            check_curl || { print_error "curl is required but not found"; exit 1; }
            continue
        fi
        check_component "$comp" || { confirm "Install $(label_of "$comp")?" "y" && install_component "$comp"; }
    done

    echo ""
    run_health_check "${NEEDED[@]}"
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    print_banner

    # Targeted mode: if any arguments are passed, only check/install those components
    if [[ "$#" -gt 0 ]]; then
        run_targeted "$@"
        return
    fi

    local arch
    arch=$(detect_arch)

    echo -e "${BOLD}System Info:${NC}"
    echo "  macOS $(sw_vers -productVersion)  |  arch: $arch"
    echo ""

    if detect_rosetta; then
        print_warning "Running under Rosetta 2 (x86 emulation on ARM Mac)"
        explain "Some tools may install as x86. Consider: arch -arm64 /bin/zsh"
        echo ""
    fi

    # ─────────────────────────────────────────────────────────────────────
    # Phase 1: Foundation
    # ─────────────────────────────────────────────────────────────────────
    echo -e "${BOLD}Phase 1: Foundation${NC}"
    echo "════════════════════════════════════════════════"

    check_curl || { print_error "curl is required"; exit 1; }

    if ! check_xcode_tools; then
        if confirm "Install Xcode Command Line Tools?"; then
            install_xcode_tools
        else
            print_error "Xcode CLT required (provides git, make, clang)"
            exit 1
        fi
    fi

    if ! check_homebrew; then
        if confirm "Install Homebrew?"; then
            install_homebrew
        else
            print_error "Homebrew is required to install remaining tools"
            exit 1
        fi
    fi

    # ─────────────────────────────────────────────────────────────────────
    # Phase 2: Core Dev Tools
    # ─────────────────────────────────────────────────────────────────────
    echo ""
    echo -e "${BOLD}Phase 2: Core Dev Tools${NC}"
    echo "════════════════════════════════════════════════"

    check_git  || { confirm "Install Git?"  && install_git;  }
    check_python || { confirm "Install Python 3.12?" && install_python; }
    check_ssl_certs
    check_node || { confirm "Install Node.js?" && install_node; }

    # ─────────────────────────────────────────────────────────────────────
    # Phase 3: AI Tools
    # ─────────────────────────────────────────────────────────────────────
    echo ""
    echo -e "${BOLD}Phase 3: AI Tools${NC}"
    echo "════════════════════════════════════════════════"

    check_claude_code || { confirm "Install Claude Code (npm)?" && install_claude_code; }
    check_sf          || { confirm "Install Salesforce CLI (npm)?" && install_sf; }
    check_heroku      || { confirm "Install Heroku CLI?" && install_heroku; }
    check_uv          || { confirm "Install uv (Python package manager)?" && install_uv; }
    check_gh          || { confirm "Install GitHub CLI?" && install_gh; }

    # ─────────────────────────────────────────────────────────────────────
    # Phase 4: Optional Extras
    # ─────────────────────────────────────────────────────────────────────
    echo ""
    echo -e "${BOLD}Phase 4: Optional Extras${NC}"
    echo "════════════════════════════════════════════════"

    check_jq       || { if confirm "Install jq (JSON processor)?" "n"; then install_jq;     else print_info "Skipped — install later with: brew install jq"; fi; }
    check_java     || { if confirm "Install Java 21 (OpenJDK)?" "n";  then install_java;   else print_info "Skipped — install later with: brew install openjdk@21"; fi; }
    check_vscode   || { if confirm "Install VS Code?" "n";             then install_vscode; else print_info "Skipped — install later with: brew install --cask visual-studio-code"; fi; }
    check_cursor   || { if confirm "Install Cursor?" "n";              then install_cursor; else print_info "Skipped — install later with: brew install --cask cursor"; fi; }
    if command -v cursor &>/dev/null || [[ -d "/Applications/Cursor.app" ]]; then
        check_sf_extension_cursor || { if confirm "Install Salesforce Extension Pack for Cursor?" "n"; then install_sf_extension_cursor; else print_info "Skipped — install later with: cursor --install-extension salesforce.salesforcedx-vscode"; fi; }
    fi
    check_ghostty  || { if confirm "Install Ghostty terminal?" "n";    then install_ghostty; else print_info "Skipped — install later with: brew install --cask ghostty"; fi; }

    # ─────────────────────────────────────────────────────────────────────
    # Phase 6: Salesforce Git Access
    # ─────────────────────────────────────────────────────────────────────
    run_git_access_phase

    # ─────────────────────────────────────────────────────────────────────
    # Phase 7: Health Check & Next Steps
    # ─────────────────────────────────────────────────────────────────────
    echo ""
    echo -e "${BOLD}Phase 7: Verification${NC}"
    echo "════════════════════════════════════════════════"

    run_health_check

    echo ""
    echo -e "${BOLD}${GREEN}Setup complete!${NC}"
    echo ""
    echo -e "${BOLD}Next Steps:${NC}"
    echo ""
    echo "  1. Authenticate Claude Code:"
    echo "       claude"
    echo ""
    echo "  2. Authenticate GitHub CLI (optional):"
    echo "       gh auth login"
    echo ""
    echo "  3. Authenticate Salesforce CLI (optional):"
    echo "       sf org login web"
    echo ""
    echo "  4. Salesforce git access docs:"
    echo "       docs/git-soma-setup.md"
    echo "       docs/git-emu-setup.md"
    echo ""
    echo "  5. Restart your terminal (or source your shell config)"
    echo "       source $(detect_shell_rc)"
    echo ""
}

main "$@"
