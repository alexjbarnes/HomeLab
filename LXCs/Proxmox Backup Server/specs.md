# LXC 500: Proxmox Backup Server

```mermaid
graph TB
    Network[Network<br/>192.168.0.143<br/>vmbr0]
    
    subgraph LXC500["LXC 500: PBS"]
        PBS[Proxmox Backup Server<br/>Port 8007]
        Root[Root FS<br/>8GB sdb1]
        
        subgraph Storage["Storage Mounts"]
            SDA1[sda1<br/>1TB<br/>/media/sda1]
            SDB1[sdb1<br/>1TB<br/>/media/sdb1]
        end
        
        PBS --- Root
        PBS --- SDA1
        PBS --- SDB1
    end
    
    Network --> PBS
    
    Caddy[Caddy Reverse Proxy<br/>pbs.local] -.HTTPS.-> PBS
    Proxmox[Proxmox Host] -.Backup Jobs.-> PBS
    
    style LXC500 fill:#16213e,stroke:#533483,stroke-width:2px,color:#eee
    style Storage fill:#1a1a2e,stroke:#533483,stroke-width:2px,color:#eee
```

## Network
- **IP Address**: 192.168.0.143
- **Gateway**: 192.168.0.1
- **DNS**: 1.1.1.1
- **Hostname**: PBS
- **MAC Address**: BC:24:11:FC:F0:60

## Resources
- **CPU**: 1 Core
- **Memory**: 2GB RAM
- **Swap**: 0GB
- **Root Filesystem**: 8GB (sdb1)

## Storage Mounts
- **sda1**: 1TB storage (mounted at /media/sda1)
- **sdb1**: 1TB storage (mounted at /media/sdb1)

## Configuration
- **Architecture**: amd64
- **OS Type**: Debian
- **Features**: Nesting enabled
- **Privileged**: No (unprivileged container)
- **Auto Start**: Yes

## Services
- **Proxmox Backup Server**: Web UI on port 8007
- **Purpose**: Backup storage for VMs and LXCs

## DNS Routes
- **pbs.local** → 192.168.0.143:8007
