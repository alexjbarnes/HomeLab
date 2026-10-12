---
category: convention
subject: graphene-store-vs-public-repo
---

This repo is public (github.com:alexjbarnes/HomeLab), and .graphene/nodes/ and .graphene/facts/ are committed and therefore published. Write node observations and project facts accordingly: LAN IPs, ports, hostnames and the Tailscale IP/tailnet name are already public elsewhere in the repo, but anything credential-shaped must not go in. Global facts are stored at ~/.graphene/global/ and session data at ~/.graphene/sessions/, both outside the repo, so they are never pushed; that is where machine- or user-specific detail belongs. A leftover context.db.migrated sqlite artifact (empty schema, no rows) sat untracked in .graphene/ until it was deleted on 2026-10-10.
