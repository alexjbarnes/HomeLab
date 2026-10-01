# DNS and TLS Debug Guide

Pi-hole + Tailscale + Caddy troubleshooting for the homelab.

## Architecture

```
App on device -> Tailscale resolver (100.100.100.100, on the device)
                   -> Pi-hole (100.77.12.68) -> Google (8.8.8.8 / 8.8.4.4)
                   -> Cloudflare (1.1.1.1 / 1.0.0.1, via DNS-over-HTTPS)
```

With Tailscale DNS on, every device resolves through 100.100.100.100, a resolver built
into Tailscale on that device. It sends each query to all the nameservers set in the
admin console at the same time and uses the first usable answer. SERVFAIL and REFUSED
don't count, so a lookup only fails outright when every nameserver fails or the device's
Tailscale resolver is stuck.

Pi-hole's own upstreams are Google (8.8.8.8 / 8.8.4.4), not Cloudflare.

## Triage: DNS failing on a device

Work down the list and stop at the first check that fails. Checks 2 and 3 need a network
tools app that can query a specific DNS server.

| # | Check | If it fails |
|---|---|---|
| 1 | Open http://100.77.12.68:880/admin on the device | Tunnel is down. See "Stale Tailscale on Android" |
| 2 | Look up google.com against 100.77.12.68 | Pi-hole isn't answering this device. See "Pi-hole checks" |
| 3 | Look up google.com against 100.100.100.100 | Tailscale isn't using Pi-hole. See "Override local DNS switched off" and "Stale Tailscale on Android" |
| 4 | Checks 1 to 3 pass but apps still fail | Android isn't sending DNS to Tailscale. See the Private DNS and Chrome Secure DNS issues |

If check 2 passes but check 3 fails, repeat check 3 from a second device. Both failing
means the tailnet's DNS settings are wrong, which affects every device. Only the first
device failing means its Tailscale app is stuck.

Failing on external names as well as `.lan` points at the device or the tailnet settings
rather than Pi-hole, because Cloudflare would still answer external names. `.lan` names
failing while external names resolve points at Tailscale not reaching Pi-hole.

To see which resolver is really answering, look up whoami.akamai.net against 100.100.100.100
and 100.77.12.68. The answer is the IP of whichever resolver replied. If the two differ,
Tailscale isn't using Pi-hole.

## Pi-hole checks

Is Pi-hole answering?

```bash
dig @100.77.12.68 google.com
dig @100.77.12.68 immich.lan
```

Which upstreams is it using, and are they failing? Each entry is `server#port queries failures`.

```bash
dig @100.77.12.68 servers.bind chaos txt
```

Are the device's queries reaching it? Watch the log while making a request from the device:

```bash
docker exec -it pihole pihole -t
```

Or check the web UI under Query Log. If the device's queries don't appear, the problem is
between the device and Pi-hole (Tailscale tunnel or DNS config).

Is it refusing a client? Tools > Pi-hole diagnosis in the web UI lists "rate-limited"
warnings. Pi-hole answers REFUSED to any client sending more than 1000 queries a minute.

## Known recurring issues

### Stale Tailscale on Android

**Symptoms:** Tailscale shows connected but every lookup fails, internal and external.
Either nothing loads at all, or the Pi-hole admin page loads by IP while names don't
resolve. In the second case triage check 2 passes and check 3 fails.

**Cause:** The Tailscale app's tunnel or its resolver (100.100.100.100) gets stuck.
Toggling Tailscale off and on in the app only reconnects the VPN, so a stuck resolver
keeps running. On 2026-09-27 a phone reboot didn't clear it either.

**Fix:**
1. Send a bug report first (Tailscale app > Settings > Bug report) and note the ID, so
   Tailscale can see what caused it
2. Force-stop Tailscale from Android Settings > Apps > Tailscale, then relaunch
3. Look up google.com against 100.100.100.100 again to confirm

### Cloudflare nameservers answering instead of Pi-hole

**Symptoms:** Some ads get through, or `.lan` names intermittently fail with NXDOMAIN,
more often away from home. Pi-hole and every device setting look correct.

**Cause:** Tailscale sends each query to Pi-hole and Cloudflare at the same time and uses
whichever answers first. Cloudflare doesn't block ads, and its NXDOMAIN for `.lan` names
still counts as an answer. When Pi-hole is slower to reach, for example over a relayed
Tailscale connection, Cloudflare wins.

**Fix:**
1. In admin.tailscale.com > DNS, add 100.77.12.68 as a nameserver restricted to the
   `lan` domain (split DNS), so `.lan` names only ever go to Pi-hole
2. To stop ads leaking too, remove the Cloudflare nameservers. Pi-hole then becomes a
   single point of failure for DNS across the tailnet

### Override local DNS switched off

**Symptoms:** Ads appearing on Android, or `.lan` names returning NXDOMAIN on every device
while external names still resolve. Pi-hole works when queried directly, the Tailscale app
shows "Using Tailscale DNS" with the correct resolvers, and Private DNS is off. Everything
looks correct but queries bypass Pi-hole.

**Cause:** The "Override local DNS" toggle in the Tailscale admin console got disabled, so
100.100.100.100 sends queries to the local network's DNS (the router) instead of the
configured nameservers. The router doesn't know `.lan` names. The Tailscale app still
reports everything as healthy. This toggle has flipped at least twice, and force-stopping
Tailscale or rebooting the phone won't fix it.

**Fix:**
1. Go to admin.tailscale.com > DNS
2. Enable "Override local DNS"
3. Verify by checking Pi-hole query log for device traffic
4. Check the Logs page in the admin console, which records DNS settings changes, to see
   when and how it was switched off

If the toggle is already on, see "Cloudflare nameservers answering instead of Pi-hole".

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

Configured in admin.tailscale.com > DNS > Nameservers. Tailscale queries all of them at
once, so the Cloudflare entries aren't only used when Pi-hole fails.

| Resolver | Purpose |
|---|---|
| 100.77.12.68 | Pi-hole (ad blocking, `.lan` names) |
| 1.1.1.1 | Cloudflare (IPv4) |
| 1.0.0.1 | Cloudflare (IPv4) |
| 2606:4700:4700::1111 | Cloudflare (IPv6) |
| 2606:4700:4700::1001 | Cloudflare (IPv6) |
