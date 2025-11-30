# HomeLab Infrastructure

```mermaid
graph TB
    subgraph Proxmox["Proxmox Host (192.168.0.93)"]
        subgraph PBS_LXC["LXC: Proxmox Backup Server (192.168.0.143)"]
            PBS[Proxmox Backup Server<br/>Port 8007]
            PBS_Storage1[Local HDD 200GB]
            PBS_Storage2[NFS HDD 200GB]
            PBS --- PBS_Storage1
            PBS --- PBS_Storage2
        end
        
        subgraph Docker_VM["VM: Docker Host (192.168.0.137)"]
            Caddy[Caddy Reverse Proxy<br/>Ports 80/443]
            
            subgraph Komodo_Stack["Komodo Stack"]
                Mongo[(MongoDB)]
                Komodo_Core[Komodo Core<br/>Port 9120]
                Komodo_Periphery[Komodo Periphery]
                Docker_Socket[Docker Socket]
                Komodo_Core --- Mongo
                Komodo_Periphery -.Mounts.-> Docker_Socket
            end
            
            subgraph Media_Stack["Media Services"]
                Jellyfin[Jellyfin<br/>Host Network<br/>GPU Passthrough]
                Debrid[Debrid Downloader<br/>Port 3333]
                Media_Storage[Media Storage]
                Jellyfin --- Media_Storage
                Debrid --- Media_Storage
            end
            
            subgraph Apps["Applications"]
                PiHole[Pi-hole DNS<br/>Ports 53/880]
                Vikunja[Vikunja Tasks<br/>Port 3456]
                Mealie[Mealie Recipes<br/>Port 9925]
                Wallabag[Wallabag<br/>Port 8880]
                PgAdmin[pgAdmin<br/>Port 8080]
            end
            
            Caddy --> Komodo_Core
            Caddy --> Debrid
            Caddy --> Vikunja
            Caddy --> PiHole
            Caddy --> PBS
        end
        
        subgraph Dev_VM["VM: Dev Environment"]
            Dev_Container[Dev Container]
        end
    end
    
    PBS -.Backups.-> Docker_VM
    PBS -.Backups.-> Dev_VM
    
    Internet((Internet)) --> Caddy
    
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
    style Komodo_Stack fill:#16213e,stroke:#e94560,stroke-width:2px,color:#eee
    style Media_Stack fill:#16213e,stroke:#e94560,stroke-width:2px,color:#eee
    style Apps fill:#16213e,stroke:#e94560,stroke-width:2px,color:#eee
    style DNS_Routes fill:#1a1a2e,stroke:#16213e,stroke-width:2px,color:#eee
```

## Overview

This HomeLab runs on Proxmox and consists of:

### LXC Container
- **Proxmox Backup Server (192.168.0.143)** - Dual 200GB storage (local + NFS)

### Docker VM (192.168.0.137)
- **Caddy** - Reverse proxy handling TLS termination
- **Komodo Stack** - Infrastructure management (Core + Periphery + MongoDB)
- **Media Services** - Jellyfin with GPU passthrough, Debrid downloader
- **Pi-hole** - DNS/ad-blocking
- **Productivity Apps** - Vikunja, Mealie, Wallabag, pgAdmin

### Dev VM
- Development container environment

All services route through Caddy with local DNS entries configured in Pi-hole for convenient .local domain access.
