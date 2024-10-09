#!/bin/bash
set -e

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

check_command() {
    if [ $? -ne 0 ]; then
        log "Error: $1 failed"
        exit 1
    fi
}

log "Displaying PCI devices"
lspci
check_command "lspci"

log "Displaying block devices"
lsblk
check_command "lsblk"

log "Creating a new partition on the NVMe drive"
fdisk /dev/nvme0n1 << EOF
n
p
1


a
1
w
EOF
check_command "Creating partition"

log "Cloning SD card to NVMe drive"
dd if=/dev/mmcblk0 of=/dev/nvme0n1 bs=4M status=progress
check_command "Cloning SD card"

log "Syncing data to NVMe"
sync

log "Creating a new data partition on the NVMe drive"
fdisk /dev/nvme0n1 << EOF
n
p
4


w
EOF
check_command "Creating data partition"

log "Creating ext4 filesystem on the new partition"
mkfs.ext4 /dev/nvme0n1p4
check_command "Creating ext4 filesystem"

log "Creating mount point directory"
mkdir -p /mnt/data
check_command "Creating mount point"

log "Mounting the new partition"
mount /dev/nvme0n1p4 /mnt/data
check_command "Mounting partition"

log "Displaying mounted partition information"
df -h | grep /mnt/data
check_command "Displaying partition info"

log "Getting UUID of the new partition"
blkid /dev/nvme0n1p4
check_command "Getting partition UUID"

log "Setting ownership and permissions for /mnt/data"
chown rpi:rpi /mnt/data
chmod 775 /mnt/data
check_command "Setting ownership and permissions"

log "Adding entry to /etc/fstab for automatic mounting"
UUID=$(blkid -s UUID -o value /dev/nvme0n1p4)
echo "UUID=$UUID /mnt/data ext4 defaults 0 2" >> /etc/fstab
check_command "Updating /etc/fstab"

log "Script completed successfully. Rebooting..."
reboot
