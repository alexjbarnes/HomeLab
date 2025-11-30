# HomeLab Infrastructure

```mermaid
graph TB
    subgraph Proxmox["Proxmox Host (192.168.0.93)"]
        subgraph PBS_LXC["LXC 500: PBS (192.168.0.143)"]
            PBS[Proxmox Backup Server<br/>Port 8007<br/>1 Core | 2GB RAM | 8GB Root]
            PBS_Storage1[sda1: 1TB]
            PBS_Storage2[sdb1: 1TB]
            PBS --- PBS_Storage1
            PBS --- PBS_Storage2
        end
        
        subgraph Docker_VM["VM 200: Docker (192.168.0.137)"]
            VM200_Specs[4 Cores | 8GB RAM | 100GB Boot<br/>Intel iGPU Passthrough<br/>Storage: 2TB + 4.1TB]
            
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
                Jellyfin[Jellyfin<br/>Host Network<br/>GPU HW Accel]
                Debrid[Debrid Downloader<br/>Port 3333]
                Immich[Immich Photos]
                Frigate[Frigate NVR]
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
                Backrest[Backrest Backup]
                Kanbn[Kanbn Board]
                PrintScan[Print/Scan Server<br/>Canon Driver]
            end
            
            Caddy --> Komodo_Core
            Caddy --> Debrid
            Caddy --> Vikunja
            Caddy --> PiHole
            Caddy --> PBS
        end
        
        subgraph Dev_VM["VM 100: Dev (DHCP)"]
            Dev_Specs[8 Cores | 16GB RAM | 100GB Disk]
            Dev_Container[Dev Container]
        end
        
        subgraph Template["VM 1000: Alpine Template"]
            Template_Specs[1 Core | 512MB RAM | 2GB Disk]
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

### Network Access
- **Tailscale VPN** - Secure remote access, no exposed ports to internet

### LXC 500: Proxmox Backup Server (192.168.0.143)
- **Resources**: 1 Core | 2GB RAM | 8GB Root filesystem
- **Storage**: Dual 1TB HDDs (sda1 + sdb1) for backup storage
- **Services**: PBS Web UI on port 8007

### VM 200: Docker Host (192.168.0.137)
- **Resources**: 4 Cores | 8GB RAM | 100GB Boot disk
- **Hardware Passthrough**: Intel iGPU for hardware transcoding
- **Storage**: 2TB + 4.1TB data disks
- **USB Passthrough**: Canon printer/scanner hardware

#### Services
- **Reverse Proxy**: Caddy (ports 80/443) with local TLS
- **Infrastructure**: Komodo (Core + Periphery + MongoDB)
- **Media**: Jellyfin (GPU transcoding), Debrid downloader, Immich photos, Frigate NVR
- **Network**: Pi-hole DNS/ad-blocking (ports 53/880)
- **Productivity**: Vikunja tasks, Mealie recipes, Wallabag, Kanbn board
- **Admin**: pgAdmin, Backrest backups, Print/Scan server

### VM 100: Dev Environment
- **Resources**: 8 Cores | 16GB RAM | 100GB Disk
- **IP**: DHCP assigned
- **Purpose**: Development container host

### VM 1000: Alpine Template
- **Resources**: 1 Core | 512MB RAM | 2GB Disk
- **Purpose**: Base template for cloning new VMs

All services route through Caddy with local DNS entries configured in Pi-hole for convenient .local domain access. External access is secured via Tailscale VPN on the Proxmox host.
