---
type: subsystem
summary: Proxmox host (pve) guest inventory: exported VM/LXC configs, per-guest specs.md docs and the infrastructure.md diagram
entry_points:
  - infrastructure.md
  - qemu-server/200.conf
  - lxc/500.conf
covers:
  - qemu-server/**
  - lxc/**
  - VMs/*/specs.md
  - LXCs/**
  - infrastructure.md
  - VMs/Observability/**
last_commit: 7e282125c419355d91f60cb28d15eb939558d322
---

- Observability VM on the pve host is only partially in the repo (as of 935a0ec). Only VMs/Observability/Komodo/InfluxDB/compose.yaml exists (influxdb:2 on 8086, added 817ab70 on 2025-12-31). There is no qemu-server/<vmid>.conf for it, no VMs/Observability/specs.md, and it is absent from infrastructure.md. qemu-server/ holds only 100 Dev-VM, 200 Docker, 1000 AlpineVmTemplate; lxc/ holds only 500 PBS. Its VMID and IP are not recorded anywhere in the repo. <!-- id:65c6 -->
- Working tree (2026-09-24) adds VMs/Observability/Komodo/komodo/compose.yaml for the Observability VM's Komodo Periphery. The VM's Proxmox config, VMID and IP are still not in the repo. <!-- id:939b -->
