---
category: convention
subject: exposing-a-new-lan-service
---

Exposing a new *.lan service takes two edits, both in VMs/Docker/Komodo/: a site block in caddy/Caddyfile, and a line in pihole/custom.list. custom.list must always point at 192.168.0.137, not the backend host: Caddy runs there and terminates the local_certs TLS for *.lan. There is no wildcard DNS entry in pihole/custom-dns.conf (only addn-hosts for custom.list), so every name needs its own line or it will not resolve. Redeploying is done through Komodo, not by hand.
