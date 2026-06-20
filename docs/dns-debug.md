# DNS and TLS Debug Guide

Pi-hole + Tailscale + Caddy troubleshooting for the homelab.

## Architecture

```
Device -> Tailscale VPN -> Pi-hole (100.77.12.68) -> Cloudflare (1.1.1.1 / 1.0.0.1)
```

Tailscale DNS config includes Cloudflare as fallback resolvers alongside Pi-hole.
All queries should route through Pi-hole for ad blocking. Cloudflare is the upstream
resolver configured inside Pi-hole and listed as fallback in Tailscale.

## Quick checks

### 1. Is Pi-hole responding?

```bash
dig @100.77.12.68 google.com
```

If this works, Pi-hole is healthy.

### 2. Is your device sending queries to Pi-hole?

Watch the Pi-hole query log while making a request from the device:

```bash
pihole -t
```

Or check the Pi-hole web UI under Query Log. If your device's queries don't appear,
the problem is between the device and Pi-hole (Tailscale tunnel or DNS config).

### 3. Is Tailscale connected?

On the device, open the Tailscale app and confirm it shows connected. Force-stop and
relaunch if the status looks stale.

## Known recurring issues

### Android not using Pi-hole despite Tailscale showing healthy

**Symptoms:** Ads appearing on Android. Pi-hole works when queried directly. Tailscale
app shows "Using Tailscale DNS" with the correct resolvers. Private DNS is off.
Everything looks correct but queries bypass Pi-hole.

**Cause:** The "Override local DNS" toggle in the Tailscale admin console got disabled.
When off, the device's local network DNS takes priority even though the Tailscale app
still reports everything as healthy. This toggle can reset after Tailscale updates or
admin console changes.

**Fix:**
1. Go to admin.tailscale.com > DNS
2. Enable "Override local DNS"
3. Verify by checking Pi-hole query log for device traffic

### Android Private DNS overriding Tailscale

**Symptoms:** Same as above but "Private DNS" in Android settings is set to "Automatic"
or a specific provider.

**Fix:** Android Settings > Network & Internet > Private DNS > set to "Off"

### Chrome Secure DNS bypassing Tailscale

**Symptoms:** `.lan` domains return `DNS_PROBE_FINISHED_NXDOMAIN` in Chrome. Direct
DNS queries to Pi-hole (e.g. from a network tools app) work fine. Other apps may
also work. Problem persists across Wi-Fi and mobile data.

**Cause:** Chrome has its own "Use secure DNS" setting independent from Android's
Private DNS. When enabled, Chrome sends DNS-over-HTTPS directly to Google or
Cloudflare, bypassing the Tailscale VPN tunnel. Public DNS providers don't know
about `.lan` domains.

**Fix:** Chrome > Settings > Privacy and security > Use secure DNS > set to "Off"
or "Use your current service provider"

### Stale Tailscale VPN tunnel on Android

**Symptoms:** Tailscale shows connected but DNS and/or connectivity is broken.

**Fix:** Force-stop Tailscale from Android Settings > Apps > Tailscale, then relaunch.
A simple toggle off/on from the app is sometimes not enough.

### Caddy internal TLS cert expired

**Symptoms:** Browser shows `NET::ERR_CERT_DATE_INVALID` for `.lan` domains. Certificate
issuer is "Caddy Local Authority - ECC Intermediate". DNS resolution works (the page
loads but with a cert warning).

**Cause:** Caddy's internally generated TLS certificate has expired. Caddy auto-renews
these but sometimes needs a restart to serve the renewed cert.

**Fix:**
1. Restart Caddy: `docker restart caddy`
2. If that doesn't work, the local CA root cert itself may have expired. Delete Caddy's
   CA data and let it regenerate:
   ```bash
   # inside the caddy container
   rm -rf /data/caddy/pki
   ```
3. Restart Caddy again. Devices will need to re-trust the new root CA.

## Android device settings reference

These should be set for Pi-hole DNS to work:

| Setting | Location | Value |
|---|---|---|
| Private DNS | Android > Network > More connection settings | Off |
| Chrome Secure DNS | Chrome > Privacy and security > Use secure DNS | Off |
| Use Tailscale DNS | Tailscale app > Settings > DNS settings | On |
| Override local DNS | admin.tailscale.com > DNS | On |
| Battery optimization | Android > Apps > Tailscale > Battery | Unrestricted |
| Always-on VPN | Android > Network > VPN > Tailscale gear | On |

## Tailscale DNS resolvers

Configured in admin.tailscale.com > DNS > Nameservers:

| Resolver | Purpose |
|---|---|
| 100.77.12.68 | Pi-hole (primary, handles ad blocking) |
| 1.1.1.1 | Cloudflare fallback (IPv4) |
| 1.0.0.1 | Cloudflare fallback (IPv4) |
| 2606:4700:4700::1111 | Cloudflare fallback (IPv6) |
| 2606:4700:4700::1001 | Cloudflare fallback (IPv6) |
