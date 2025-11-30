# HomeLab Infrastructure

```mermaid
graph TB
    Tailscale[Tailscale VPN] --> Proxmox
    
    subgraph Proxmox["Proxmox Host (192.168.0.93)"]
        PBS_LXC[LXC 500: PBS<br/>192.168.0.143]
        Docker_VM[VM 200: Docker<br/>192.168.0.137]
        Dev_VM[VM 100: Dev<br/>DHCP]
        Template[VM 1000: Alpine Template]
    end
    
    PBS_LXC -.Backups.-> Docker_VM
    PBS_LXC -.Backups.-> Dev_VM
    
    style Proxmox fill:#1a1a2e,stroke:#16213e,stroke-width:2px,color:#eee
    style Docker_VM fill:#0f3460,stroke:#16213e,stroke-width:2px,color:#eee
    style PBS_LXC fill:#16213e,stroke:#533483,stroke-width:2px,color:#eee
    style Dev_VM fill:#1a1a2e,stroke:#16213e,stroke-width:2px,color:#eee
    style Template fill:#1a1a2e,stroke:#16213e,stroke-width:2px,color:#eee
```

## Overview

This HomeLab runs on Proxmox and consists of:

### Devices
- [LXC 500: Proxmox Backup Server](LXCs/Proxmox%20Backup%20Server/specs.md) (192.168.0.143)
- [VM 200: Docker Host](VMs/Docker/specs.md) (192.168.0.137)
- [VM 100: Dev Environment](VMs/Dev%20VM/specs.md) (DHCP)
- [VM 1000: Alpine Template](VMs/Alpine%20Template/specs.md)

### Network Access
External access is secured via Tailscale VPN on the Proxmox host. No ports exposed to internet.

All services route through Caddy reverse proxy with local DNS entries configured in Pi-hole for convenient .local domain access.
