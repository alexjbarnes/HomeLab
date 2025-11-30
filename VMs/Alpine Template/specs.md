# VM 1000: Alpine Template

```mermaid
graph TB
    subgraph VM1000["VM 1000: Alpine Template"]
        Template[Alpine Linux<br/>Base Template]
        
        subgraph Resources["Resources"]
            CPU[1 Core<br/>x86-64-v2-AES]
            RAM[512MB RAM]
            Disk[2GB Base Image<br/>local-lvm]
        end
        
        Template --- Resources
    end
    
    VM1000 -.Clone.-> NewVM[New VM Instance]
    
    style VM1000 fill:#1a1a2e,stroke:#16213e,stroke-width:2px,color:#eee
    style Resources fill:#0f3460,stroke:#16213e,stroke-width:2px,color:#eee
```

## Network
- **MAC Address**: BC:24:11:65:9A:EA
- **Bridge**: vmbr0

## Resources
- **CPU**: 1 Core (x86-64-v2-AES)
- **Memory**: 512MB RAM
- **Boot Disk**: 2GB (local-lvm, base image)

## Configuration
- **Name**: AlpineVmTemplate
- **BIOS**: OVMF (UEFI)
- **OS Type**: Linux 2.6+ Kernel
- **SCSI Controller**: VirtIO SCSI Single
- **QEMU Agent**: Enabled
- **NUMA**: Disabled
- **Template**: Yes

## Purpose
Base Alpine Linux template for cloning new lightweight VMs.
