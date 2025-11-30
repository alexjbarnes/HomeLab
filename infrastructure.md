# HomeLab Infrastructure

```mermaid
graph TB
    subgraph Proxmox["Proxmox Host (192.168.0.93)"]
        subgraph PBS_LXC["LXC 500: PBS"]
            PBS[Proxmox Backup Server]
            PBS_Storage1[sda1: 1TB]
            PBS_Storage2[sdb1: 1TB]
            PBS --- PBS_Storage1
            PBS --- PBS_Storage2
        end
        
        subgraph Docker_VM["VM 200: Docker"]
            Caddy[Caddy Reverse Proxy]
            
            subgraph Komodo_Stack["Komodo Stack"]
                Mongo[(MongoDB)]
                Komodo_Core[Komodo Core]
                Komodo_Periphery[Komodo Periphery]
                Docker_Socket[Docker Socket]
                Komodo_Core --- Mongo
                Komodo_Periphery -.Mounts.-> Docker_Socket
            end
            
            subgraph Media_Stack["Media Services"]
                Jellyfin[Jellyfin]
                Debrid[Debrid Downloader]
                Immich[Immich Photos]
                Frigate[Frigate NVR]
                Media_Storage[Media Storage]
                Jellyfin --- Media_Storage
                Debrid --- Media_Storage
            end
            
            subgraph Apps["Applications"]
                PiHole[Pi-hole DNS]
                Vikunja[Vikunja Tasks]
                Mealie[Mealie Recipes]
                Wallabag[Wallabag]
                PgAdmin[pgAdmin]
                Backrest[Backrest Backup]
                Kanbn[Kanbn Board]
                PrintScan[Print/Scan Server]
            end
            
            Caddy --> Komodo_Core
            Caddy --> Debrid
            Caddy --> Vikunja
            Caddy --> PiHole
            Caddy --> PBS
        end
        
        subgraph Dev_VM["VM 100: Dev"]
            Dev_Container[Dev Container]
        end
        
        subgraph Template["VM 1000: Alpine Template"]
            Template_Node[Alpine Base]
        end
    end
    
    PBS -.Backups.-> Docker_VM
    PBS -.Backups.-> Dev_VM
    
    Tailscale[Tailscale VPN] --> Proxmox
    
    subgraph DNS_Routes["DNS Routes (Custom)"]
        DNS1[pve.local → 192.168.0.93:8006]
        DNS2[pbs.local → 192.168.0.143:8007]
        DNS3[komodo.local → 192.168.0.137:9120]
        DNS4[debrid.local → 192.168.0.137:3333]
        DNS5[vikunja.local → 192.168.0.137:3456]
        DNS6[pihole.local → 192.168.0.137:880]
    end
    
    PiHole -.DNS Resolution.-> DNS_Routes
    
    style Proxmox fill:#1a1a2e,stroke:#16213e,stroke-width:2px,color:#eee
    style Docker_VM fill:#0f3460,stroke:#16213e,stroke-width:2px,color:#eee
    style PBS_LXC fill:#16213e,stroke:#533483,stroke-width:2px,color:#eee
    style Dev_VM fill:#1a1a2e,stroke:#16213e,stroke-width:2px,color:#eee
    style Template fill:#1a1a2e,stroke:#16213e,stroke-width:2px,color:#eee
    style Komodo_Stack fill:#16213e,stroke:#e94560,stroke-width:2px,color:#eee
    style Media_Stack fill:#16213e,stroke:#e94560,stroke-width:2px,color:#eee
    style Apps fill:#16213e,stroke:#e94560,stroke-width:2px,color:#eee
    style DNS_Routes fill:#1a1a2e,stroke:#16213e,stroke-width:2px,color:#eee
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
