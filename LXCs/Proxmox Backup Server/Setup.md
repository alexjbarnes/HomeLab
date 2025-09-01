1. Download Turnkey 12 core from CT templates
2. Set up lxc
	- 2gb ram
	- 1cpu
	- 8gb root FS
	- HDD 
		- 200gb local
		- 200gb NFS
	- DNS 1.1.1.1

## Cli commands
- SSH into ct

```
apt update
apt upgrade
apt install sudo
wget https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg
echo "deb http://download.proxmox.com/debian/pbs bookworm pbs-no-subscription" >> /etc/apt/sources.list
sudo apt update
sudo apt install proxmox-backup-server -y
```

- Add mounts to CT for hdds

## Configuring PBS in Proxmox

- In Proxmox, go to Datacenter > Storage
- Click "Add" and select "Proxmox Backup Server"
- Configure the storage:
- Enter an ID (e.g., pbs-main)
- Input the PBS IP address
- Use "root@pam" as the username
- Enter the root password
- Specify the datastore name (e.g., pbs-main)
- Paste the PBS fingerprint (found in PBS web interface under Configuration > Certificates > View Certificate)

## Setting Up Backups

- In Proxmox, navigate to Datacenter > Backup
- Click "Add" to create a new backup job
- Select the PBS storage created earlier (e.g., pbs-main)
- Set the backup schedule
- Choose the VMs and LXC containers to back up





