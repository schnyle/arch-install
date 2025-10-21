#!/bin/bash

ARCH_INSTALL_DIR="$(dirname "$(realpath "$0")")"
source "$ARCH_INSTALL_DIR/scripts/helpers/log.sh"

# log output
exec > >(tee /var/log/arch-install.log) 2>&1

log "starting Arch Linux install"

# assumes steps 1., 2., 3.1, 3.2 are already completed

# 3. Configure the system
# steps 3.1 & 3.2 are done elsewhere
bash "$ARCH_INSTALL_DIR/scripts/system-configuration.sh"

# enable multilib repository for 32-bit packages
sed -i '/^#\[multilib\]/,/^#Include/ {s/^#//; }' /etc/pacman.conf

# sync package database after chroot
pacman -Sy

bash "$ARCH_INSTALL_DIR/scripts/post-installation.sh"
