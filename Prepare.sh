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

if [[ $EUID -ne 0 ]]; then
   log "This script must be run as root"
   exit 1
fi

log "Updating config.txt"
cat << EOF >> /boot/firmware/config.txt
[all]
dtparam=nvme
dtparam=pciex1_gen=3
EOF
check_command "Updating config.txt"

log "Setting boot order to boot from USB/NVMe"
raspi-config nonint do_boot_order B2
check_command "Configuring boot order"

log "Rebooting system to apply changes"
reboot
