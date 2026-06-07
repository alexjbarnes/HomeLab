# Gmail MCP Setup

Personal Gmail access for Claude via the community `@gongrzhe/server-gmail-autoauth-mcp` package.

## Background

### Why not Google's official Gmail MCP API
Google publishes a hosted MCP server at `gmailmcp.googleapis.com` and provides setup docs for it. After full setup with correct scopes, test users, and consent screen configuration, every call still returns `"The caller does not have permission"`. The MCP API is part of the **Google Workspace Developer Preview Program** and rejects tokens from personal Gmail accounts (anything ending in `@gmail.com`). It only works with Workspace accounts enrolled in the preview program.

### Why this package instead
`@gongrzhe/server-gmail-autoauth-mcp` is a community-built MCP server that talks to the **standard Gmail API** (not the restricted MCP API). The standard API accepts personal accounts. Scopes used are `gmail.modify` and `gmail.settings.basic`, which are restricted scopes but work for test users without app verification.

### Why it isn't routed through Conduit
Conduit (the homelab MCP proxy) only speaks HTTP to downstream MCP servers. This package is stdio-only — it expects to be spawned as a subprocess by Claude. Bridging stdio MCP servers through Conduit would need an additional wrapper.

So Gmail MCP runs as a Claude-spawned subprocess directly. Other MCP servers (Linear, Context7, vault-sync) still go through Conduit.

## Prerequisites

- A machine that will run Claude CLI and the Gmail MCP subprocess (here: Dev VM)
- Node.js 18+ available via `npx`
- A Google account (personal Gmail works)
- SSH access to the machine if running auth from mobile

## Step 1: Google Cloud Project

### Create the project
1. Console → Create Project → name it anything (e.g. `cockpit`)
2. Select the project

### Enable Gmail API
1. APIs & Services → Library
2. Search for "Gmail API"
3. Enable

### Configure OAuth consent screen
1. APIs & Services → OAuth consent screen (now under "Google Auth Platform")
2. User Type: **External**
3. App information:
   - App name: anything (e.g. `Gmail MCP Local`)
   - User support email: your email
   - Developer contact: your email
4. Save and continue

### Add scopes
1. Google Auth Platform → Data Access → Add or Remove Scopes
2. Under "Manually add scopes" paste:
   ```
   https://www.googleapis.com/auth/gmail.modify
   https://www.googleapis.com/auth/gmail.settings.basic
   ```
3. Click "Add to Table" → Update → Save

These appear under "Your restricted scopes" → "Gmail scopes". Restricted scopes need app verification before public release, but **test users bypass verification** while the app is in Testing mode.

### Add yourself as a test user
1. Google Auth Platform → Audience
2. Confirm Publishing Status: **Testing**
3. Test users → Add users → enter your Gmail address → Save

User cap is 100 by default — plenty.

### Publish to Production (do this — avoids weekly re-auth)
> **The single most important gotcha.** While the app is in **Testing**, Google expires the OAuth **refresh token after 7 days**. The MCP server then fails every tool call with `invalid_grant` / "Gmail authentication expired" and you have to re-run the whole auth flow. It will keep happening every week.

Fix: move the app to Production.

1. Google Auth Platform → Audience → **Publish app**
2. Confirm Testing → In production
3. When it warns that restricted scopes require verification, **publish anyway** — you do NOT need verification for personal use

Production + unverified is the correct end state for a single-user personal app:
- Refresh tokens no longer expire on the 7-day rule
- You're still unverified, so at consent time you click through the "Google hasn't verified this app" warning (Advanced → Go to `<app name>`)
- **Ignore the Verification Centre entirely** — that's Google's multi-week CASA security review, only needed to drop the warning for the general public. Publishing status (Testing/Production) and verification are independent.

Publishing does NOT expose your mailbox. OAuth data access always requires a user to log into a Google account and consent; tokens only ever reach the mailbox of whoever authenticated. A stranger running your app's flow would authorise their own account, never yours. What protects your email is your Google login and the `~/.gmail-mcp/credentials.json` file on the VM — keep that file private.

### Create OAuth client
1. APIs & Services → Credentials → Create Credentials → OAuth client ID
2. Application type: **Desktop app**
3. Name: anything (e.g. `Gmail MCP Local`)
4. Create
5. Download the JSON (button on the confirmation dialog or via the row's download icon)

The downloaded file looks like:
```json
{
  "installed": {
    "client_id": "...apps.googleusercontent.com",
    "client_secret": "GOCSPX-...",
    "redirect_uris": ["http://localhost"],
    ...
  }
}
```

## Step 2: Save Credentials on the Server

SSH to the machine where Claude CLI runs (Dev VM):

```sh
mkdir -p ~/.gmail-mcp
# Then copy the downloaded JSON to:
#   ~/.gmail-mcp/gcp-oauth.keys.json
```

Easiest copy methods:
- `scp client_secret_*.json user@dev-vm:~/.gmail-mcp/gcp-oauth.keys.json`
- Or paste the contents directly via a text editor in your SSH session

Verify:
```sh
cat ~/.gmail-mcp/gcp-oauth.keys.json
```

Should show valid JSON with `installed.client_id` and `installed.client_secret`.

## Step 3: Run the Auth Flow

The auth command starts a local HTTP listener on port 3000, prints a Google consent URL, opens a browser (or asks you to), and captures the redirect.

```sh
npx -y @gongrzhe/server-gmail-autoauth-mcp auth
```

Expected output:
```
Please visit this URL to authenticate: https://accounts.google.com/o/oauth2/v2/auth?...
```

If you can open a browser on the same machine, do so and the flow completes.

### Headless / Mobile Auth via SSH Port Forward

When the server has no browser (Dev VM is headless) and you're on mobile, Google's redirect to `http://localhost:3000/oauth2callback` won't reach the server's listener directly. SSH local port forwarding fixes that: tunnel phone's localhost:3000 → SSH → server's localhost:3000.

**Termius setup (Android/iOS)**:

1. Add the SSH host (Dev VM) if not already added
2. Test the SSH connection by opening a terminal session — must work before port forwarding will
3. Go to Port Forwarding → New → **Local**
4. Configure the rule:

   | Field | Value |
   |-------|-------|
   | Label | anything (e.g. `gmail-mcp`) |
   | Local Port | `3000` |
   | Bind address | leave empty initially; if rule won't activate, set to `127.0.0.1` |
   | Intermediate Host | the SSH host (Dev VM:22) |
   | Destination Address | `localhost` |
   | Destination Port | `3000` |

5. Save the rule
6. Double-click the rule to activate (single-click in Termius doesn't start it)

If the rule activates briefly then deactivates:
- The SSH session itself is failing — open a terminal session to the host first and confirm auth works
- Port 3000 is already in use on the phone
- SSH server has `AllowTcpForwarding no` (check `/etc/ssh/sshd_config` on the VM)

If the rule won't bind: set "Bind address" to `127.0.0.1` and retry.

**Completing the flow on mobile**:

1. With the tunnel active, run `npx -y @gongrzhe/server-gmail-autoauth-mcp auth` on the server (via the SSH session)
2. Copy the consent URL from the output
3. Open it in your phone's browser
4. Sign in with your test-user Gmail
5. Grant access for both scopes (`gmail.modify`, `gmail.settings.basic`)
6. Google redirects to `http://localhost:3000/oauth2callback?code=...`
7. Your phone's browser hits the tunnel → reaches the listener on the server → captures the code → exchanges for tokens

The auth command exits with a success message and creates:
```
~/.gmail-mcp/credentials.json
```

You can close the SSH tunnel after this. Tokens are persisted; the MCP server will refresh them automatically when they expire.

### Alternative: Tailscale Serve for Auth Callback

If SSH port forwarding is unavailable, expose port 3000 via Tailscale serve and use a custom callback URL:

1. On the server:
   ```sh
   tailscale serve --bg --https=443 --set-path=/oauth2callback http://localhost:3000/oauth2callback
   ```
2. Change OAuth client type from Desktop to **Web application** (Desktop type doesn't allow non-localhost redirects)
3. Add `https://<host>.tailc5f98.ts.net/oauth2callback` as authorized redirect URI in Google Cloud
4. Run auth with explicit callback:
   ```sh
   npx -y @gongrzhe/server-gmail-autoauth-mcp auth https://<host>.tailc5f98.ts.net/oauth2callback
   ```
5. Complete consent in mobile browser — redirect goes to Tailscale URL which forwards to localhost:3000 on the server

Remove the Tailscale serve route after auth completes if you don't need it long-term.

## Step 4: Add to Claude Config

Edit `~/.claude.json` and add to `mcpServers`:

```json
{
  "mcpServers": {
    "gmail": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@gongrzhe/server-gmail-autoauth-mcp"]
    }
  }
}
```

Restart Claude.

## Step 5: Verify

In Claude, run a tool that lists labels. Should return all your Gmail labels including custom ones. If it says "No access, refresh token, API key or refresh handler callback is set", the auth flow didn't complete — `~/.gmail-mcp/credentials.json` is missing.

## Files

| Path | Purpose |
|------|---------|
| `~/.gmail-mcp/gcp-oauth.keys.json` | OAuth client credentials from Google Cloud (input, manually placed) |
| `~/.gmail-mcp/credentials.json` | Issued access/refresh tokens (output, auto-managed by the auth command) |

## Available Tools

After setup the `gmail` MCP server exposes:

- **Email**: `search_emails`, `read_email`, `send_email`, `draft_email`, `delete_email`, `modify_email`, `batch_delete_emails`, `batch_modify_emails`
- **Labels**: `list_email_labels`, `create_label`, `update_label`, `delete_label`, `get_or_create_label`
- **Filters**: `list_filters`, `get_filter`, `create_filter`, `create_filter_from_template`, `delete_filter`
- **Attachments**: `download_attachment`

## Troubleshooting

| Error | Likely cause | Fix |
|-------|--------------|-----|
| `EADDRINUSE: address already in use :::3000` | Another process bound port 3000 | Find and stop it: `ss -tlnp \| grep 3000` |
| `Error: invalid_grant` during auth | Stale or already-used auth code | Re-run the auth command |
| `invalid_grant` / "Gmail authentication expired" on tool calls (worked before, dies after ~7 days) | App still in **Testing** mode — Google expires refresh tokens after 7 days | Publish app to Production (see "Publish to Production" above), then re-auth once. Restart Claude so the MCP subprocess reloads `credentials.json` |
| `Error 400: redirect_uri_mismatch` | Google client config doesn't list the callback URL | Add `http://localhost:3000/oauth2callback` (Desktop type) or your custom URL (Web type) |
| `Access blocked: Authorization Error - Some requested scopes were invalid` | Scope spelled wrong or not added in Data Access | Verify both scopes are listed in Data Access |
| Tool returns "No access, refresh token..." | `credentials.json` missing or corrupt | Re-run auth flow |
| Tool returns 403 "Insufficient Permission" | Scopes granted don't cover the operation | Re-auth, ensuring consent screen lists both scopes |
