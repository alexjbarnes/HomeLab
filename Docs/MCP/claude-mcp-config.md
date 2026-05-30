# Claude CLI MCP Config Recovery

Reference copy of the `mcpServers` block from `~/.claude.json` on the Dev VM. Claude Code updates have wiped this block (and the login session) at least once — keep this here so recovery is a paste, not a re-setup.

Tokens are redacted. Real values:
- **Conduit bearer token**: in the Conduit admin UI under the user's credentials, or the pre-update backups (`~/.claude.json.bak*`) on the Dev VM.

## Full mcpServers Block

```json
{
  "mcpServers": {
    "playwright": {
      "type": "stdio",
      "command": "npx",
      "args": ["@playwright/mcp@latest", "--headless", "--caps", "vision"],
      "env": {}
    },
    "conduit": {
      "type": "http",
      "url": "http://100.77.12.68:8080/mcp",
      "headers": {
        "Authorization": "Bearer cnd_REDACTED"
      }
    },
    "graphene": {
      "type": "stdio",
      "command": "node",
      "args": ["/home/dev/repos/graphene/dist/index.js"]
    },
    "semble": {
      "type": "stdio",
      "command": "uvx",
      "args": ["--from", "semble[mcp]", "semble"],
      "env": {}
    },
    "gmail": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@gongrzhe/server-gmail-autoauth-mcp"]
    }
  }
}
```

## Server Notes

| Server | Transport | Purpose | Depends on |
|--------|-----------|---------|------------|
| conduit | http | Proxy to Context7, Linear, vault-sync | Conduit on Docker VM, reachable at Tailscale `100.77.12.68:8080` |
| gmail | stdio | Personal Gmail (standard Gmail API) | `~/.gmail-mcp/credentials.json` — see [gmail.md](gmail.md) |
| playwright | stdio | Headless browser automation with vision | `npx` pulls `@playwright/mcp@latest` |
| graphene | stdio | Context graph for code work | `/home/dev/repos/graphene/dist/index.js` must be built |
| semble | stdio | Code search across repos | `uvx` (uv installed) |

## Conduit URL Choice
- **Tailscale direct** (`http://100.77.12.68:8080/mcp`) — works from anywhere on the tailnet via subnet routing. Current setting.
- **LAN** (`http://conduit.lan`) — only on the home network, via Caddy.
- **Tailscale serve** (`https://docker-vm.tailc5f98.ts.net/mcp`) — was used when Claude.ai needed public reach via funnel. No longer needed.

## Recovery Steps
1. SSH to Dev VM
2. Back up the current file: `cp ~/.claude.json ~/.claude.json.bak`
3. Edit `~/.claude.json`, paste the `mcpServers` block above
4. Replace `cnd_REDACTED` with the real Conduit token
5. Restart Claude
6. Verify each server connects

If Gmail fails with "No access, refresh token..." after recovery, the credentials file survived but check `~/.gmail-mcp/credentials.json` exists. If missing, re-run the auth flow in [gmail.md](gmail.md).
