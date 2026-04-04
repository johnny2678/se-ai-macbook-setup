# Git EMU Access Setup

**URL:** `github.com` (accounts ending in `_sfemu`)
**Type:** GitHub Enterprise Managed Users (cloud, Salesforce-internal orgs)

---

## Step 1: Create Your EMU Account via Okta

1. Log in to [salesforce.okta.com](https://salesforce.okta.com)
2. Search for and click the **"GitHub Salesforce - EMU"** tile
3. This provisions your `github.com` EMU account
4. Your username will end in `_sfemu` (e.g., `jsmith_sfemu`)

> **Note:** Your EMU account is separate from any personal GitHub account you may have. EMU accounts cannot be used to access GPS GitHub (standard github.com orgs) — those require a separate standard GitHub account.

---

## Step 2: Request Organization Access via IdentityIQ

1. Go to [salesforce.okta.com](https://salesforce.okta.com) and open the **IdentityIQ (IIQ)** tile
2. Click **Manage User Access** → search for and select yourself → click **Next**
3. Search for the Okta group for the specific EMU org you need:
   - Format: `GHEC_<org-name>_Users`
   - Example: `GHEC_salesforce-ux-emu_Users`
   - Not sure which group? Use the `/prodeng github-access` Slack command
4. Provide a business justification and submit

---

## Step 3: Manager Approval & Wait

- The request goes to your manager for approval via email
- After approval, access can take **20 minutes to 4+ hours** to activate
- Verify by visiting the specific GitHub EMU organization URL

---

## Step 4: Set Up Git Authentication

### Generate a Personal Access Token

1. Log in to [github.com](https://github.com) with your `_sfemu` account
2. Go to **Settings → Developer settings → Personal access tokens → Tokens (classic)**
3. Generate a new token with appropriate scopes:
   - `repo` (full repository access)
   - `read:org` (if you need to list org repos)
4. Copy the token — you won't be able to see it again

### Configure macOS Keychain (recommended)

```bash
git config --global credential.helper osxkeychain
```

### Clone a Repo & Store Credentials

```bash
git clone https://github.com/<salesforce-emu-org>/<repo>.git
```

When prompted:
- **Username:** your EMU username (ends with `_sfemu`)
- **Password:** your Personal Access Token

macOS Keychain will store the token so you won't be prompted again.

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Can't find the org after access is granted | Wait for full propagation; try logging out and back in |
| Authentication fails | Verify you're using your `_sfemu` username (not personal GitHub) and a valid token |
| Can't push to org repos | Check token has `repo` scope; check you have write access to the specific repo |
| Access to the wrong org | Request the correct `GHEC_<org-name>_Users` group in IIQ |

---

## Help

- **Slack command:** `/prodeng github-access` (lists available orgs and request process)
- **Team GitHub admins:** check with your team's GitHub org administrators for org-specific access
