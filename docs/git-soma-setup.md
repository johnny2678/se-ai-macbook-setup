# Git Soma Access Setup

**URL:** `git.soma.salesforce.com`
**Type:** GitHub Enterprise (on-premises, Salesforce-internal)

---

## Step 1: Request Active Directory Group Access

1. Go to [salesforce.okta.com](https://salesforce.okta.com) and search for **IdentityIQ (IIQ)**
2. Click **Manage User Access** and wait for it to load
3. Click your username (top-left in the grid), then click **Next**
4. Search for **Technology-RnD-Access** and select it
5. Provide a business justification, e.g.:
   > "Need access to internal GitHub Enterprise to collaborate on [project/repo name]"
6. Submit the request

> **Contractor?** Also request the **Aloha - BPO GitSoma** group in addition to `Technology-RnD-Access`.

---

## Step 2: Manager Approval

- An approval email is sent to your manager automatically
- Give your manager a heads-up — they approve via email
- You will receive a confirmation email once approved

---

## Step 3: Wait for Access to Propagate

- Access typically takes **~4 hours** after manager approval
- In some cases it can take up to **24–48 hours**
- You'll know it worked when `git.soma.salesforce.com` redirects through Salesforce Okta SSO

---

## Step 4: First Login & Account Creation

1. Navigate to [git.soma.salesforce.com](https://git.soma.salesforce.com)
2. Your user account is **automatically created** on first login via Okta SSO
3. Set your Salesforce email in your profile to receive notifications

---

## Step 5: Set Up Git Credentials

### Generate a Personal Access Token

1. In git.soma, go to **Profile → Settings → Access Tokens**
2. Create a new token with the required scopes (at minimum: `read_repository`, `write_repository`)
3. Copy the token — you won't be able to see it again

### Configure macOS Keychain (recommended)

```bash
git config --global credential.helper osxkeychain
```

### Clone a Repo & Store Credentials

```bash
git clone https://git.soma.salesforce.com/<org>/<repo>.git
```

When prompted:
- **Username:** your git.soma username (Salesforce employee ID or email prefix)
- **Password:** your Personal Access Token

macOS Keychain will store the token so you won't be prompted again.

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| "Page not found" on git.soma | AD group membership hasn't synced yet — wait or check IIQ status |
| Authentication failures | Token may be expired or missing scopes — regenerate in Access Tokens settings |
| Prompted for password on every push | Run `git config --global credential.helper osxkeychain` |

---

## Help

- **Slack:** `#scm-git-collab` or `#help-techforce`
