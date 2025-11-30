# VM 200: Docker Host

## Network
- **IP Address**: 192.168.0.137
- **Gateway**: 192.168.0.1 (via vmbr0)
- **Hostname**: Docker
- **MAC Address**: BC:24:11:C0:69:4D

## Resources
- **CPU**: 4 Cores (host CPU type)
- **Memory**: 8GB RAM
- **Boot Disk**: 100GB (local-lvm)

## Hardware Passthrough
- **GPU**: Intel iGPU (PCI 0000:00:02)
  - Used for Jellyfin hardware transcoding
- **USB Devices**:
  - 8087:0033 (USB device)
  - 04a9:18bb (Canon printer/scanner)

## Storage
- **scsi0**: 100GB boot disk (local-lvm)
- **scsi1**: 2TB data disk (sda1)
- **scsi2**: 4.1TB data disk (sda1)

## VirtioFS Mounts
- backrest_sda1
- backrest_sdb1
- PVE_CONFIG

## Configuration
- **BIOS**: OVMF (UEFI)
- **OS Type**: Linux 2.6+ Kernel
- **SCSI Controller**: VirtIO SCSI Single
- **Auto Start**: Yes
- **QEMU Agent**: Enabled

## Services

### Reverse Proxy
- **Caddy**: Ports 80/443 (local TLS certificates)

### Infrastructure Management
- **Komodo Core**: Port 9120
- **Komodo Periphery**: Docker socket monitoring
- **MongoDB**: Database for Komodo

### Media Services
- **Jellyfin**: Host network mode, GPU hardware acceleration
- **Debrid Downloader**: Port 3333
- **Immich**: Photo management
- **Frigate**: NVR for security cameras

### Network Services
- **Pi-hole**: DNS/ad-blocking (ports 53, 880)

### Productivity Apps
- **Vikunja**: Task management (port 3456)
- **Mealie**: Recipe manager (port 9925)
- **Wallabag**: Read-it-later (port 8880)
- **Kanbn**: Kanban board

### Admin Tools
- **pgAdmin**: PostgreSQL admin (port 8080)
- **Backrest**: Backup solution
- **Print/Scan Server**: Canon printer driver support

## DNS Routes
- **komodo.local** → 192.168.0.137:9120
- **debrid.local** → 192.168.0.137:3333
- **vikunja.local** → 192.168.0.137:3456
- **pihole.local** → 192.168.0.137:880
