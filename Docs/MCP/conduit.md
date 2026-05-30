# Conduit Setup

MCP proxy that routes Claude to downstream MCP servers with per-user permissions, encrypted credential storage, and audit logging.

## Adding a Downstream MCP Server

### Bearer Token Auth
For servers that take a static bearer token (Linear, Context7, vault-sync):

1. Admin UI → Servers → Add Server
2. Auth type: **Bearer**
3. Paste the token

### OAuth (Generic, with RFC 8414 Discovery)
For MCP servers that implement OAuth metadata discovery at `/.well-known/oauth-authorization-server`:

1. Auth type: **OAuth**
2. Save the server (will redirect to OAuth start)
3. Conduit discovers endpoints, performs dynamic client registration if supported
4. Browser redirects to consent screen, callback completes the flow

### OAuth (Manual — for providers without RFC 8414)
Some providers (e.g. Google) don't serve OAuth metadata at the well-known URL. Fill in manual credentials in the server edit form:

| Field | Example |
|-------|---------|
| Client ID | from Google Cloud OAuth client |
| Client Secret | from Google Cloud OAuth client |
| Authorize URL | `https://accounts.google.com/o/oauth2/v2/auth` |
| Token URL | `https://oauth2.googleapis.com/token` |
| Scope | space-separated, e.g. `https://www.googleapis.com/auth/calendar.readonly` |

Optional under "Pre-authorized tokens" disclosure:

| Field | When to use |
|-------|-------------|
| Access Token | Skip OAuth flow entirely, paste a token from somewhere else |
| Refresh Token | Same — Conduit will refresh as needed |

The Google Cloud OAuth client redirect URI must match Conduit's callback exactly:
```
http(s)://<conduit-host>/servers/<server-id>/oauth/callback
```

For Tailscale-routed Conduit instances, use the Tailscale hostname. Google rejects `.lan` domains and bare IPs.

## Why Google's Gmail MCP API Doesn't Work
Tried and abandoned. Google's `gmailmcp.googleapis.com` MCP service requires Google Workspace Developer Preview Program enrollment and rejects tokens from personal Gmail accounts with "The caller does not have permission" regardless of OAuth setup. Using the community stdio Gmail MCP server instead — see [gmail.md](gmail.md).

## Permissions
Per-user, per-server, per-tool. Admin UI → Users → edit → expand each server card to toggle tools.

When enabling a server for a user, all tools start denied — explicitly enable the ones you want.

## Network Access
- LAN: `http://conduit.lan` via Caddy
- Tailscale: `http://100.77.12.68:8080` direct (subnet routing makes this work from anywhere on the tailnet)

No `tailscale serve` config needed when subnet routing is in place.
