# VM 100: Dev Environment

```mermaid
graph TB
    Network[Network<br/>DHCP<br/>vmbr0]
    
    subgraph VM100["VM 100: Dev Environment"]
        subgraph Resources["Resources"]
            CPU[8 Cores<br/>x86-64-v2-AES]
            RAM[16GB RAM]
            Disk[100GB Boot<br/>local-lvm]
        end
        
        DevContainer[Dev Container<br/>Docker Environment]
        
        VSCode[VS Code<br/>Remote Dev]
        Git[Git Repositories]
        Build[Build Tools]
        
        DevContainer --> VSCode
        DevContainer --> Git
        DevContainer --> Build
    end
    
    Network --> DevContainer
    Developer[Developer<br/>via Tailscale] -.SSH/Remote.-> DevContainer
    
    style VM100 fill:#1a1a2e,stroke:#16213e,stroke-width:2px,color:#eee
    style Resources fill:#0f3460,stroke:#16213e,stroke-width:2px,color:#eee
```

## Network
- **IP Address**: DHCP assigned
- **MAC Address**: BC:24:11:FB:9F:25
- **Bridge**: vmbr0

## Resources
- **CPU**: 8 Cores (x86-64-v2-AES)
- **Memory**: 16GB RAM
- **Boot Disk**: 100GB (local-lvm)

## Configuration
- **Name**: Dev-VM
- **BIOS**: OVMF (UEFI)
- **OS Type**: Linux 2.6+ Kernel
- **SCSI Controller**: VirtIO SCSI Single
- **Auto Start**: Yes
- **QEMU Agent**: Enabled
- **NUMA**: Disabled

## Purpose
Development container host for testing and building applications.

## Services
- **Dev Container**: Docker-based development environment
