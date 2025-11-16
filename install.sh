#!/bin/bash

# configuration

BOOT_SIZE="512M"
SWAP_SIZE="2G"

log() { echo "$(date '+%H:%M:%S') $*" | tee -a /var/log/install.log; }

restart() { log "restarting install script" && exec "$0"; }

if [[ ! -f /var/lib/pacman/sync/core.db ]]; then
  log "initializing pacman"
  pacman-key --init
  pacman-key --populate archlinux
  pacman -Sy --noconfirm
  restart
fi

# 1. Pre-installation

# 1.8 Update the system clock
if ! timedatectl | grep -q "System clock synchronized: yes"; then
  log "updating system clock"
  timedatectl
fi

if ! mountpoint -q /mnt; then

  # 1.9 Partition the disks
  sfdisk "/dev/vda" <<EOF
label: gpt
,$BOOT_SIZE,U
,$SWAP_SIZE,S
,,L
write
EOF

  # 1.10 Format the partitions
  mkfs.fat -F32 /dev/vda1
  mkswap /dev/vda2
  swapon /dev/vda2
  mkfs.ext4 /dev/vda3

  # 1.11 Mount the file systems
  mount /dev/vda3 /mnt
  mount --mkdir /dev/vda1 /mnt/boot
fi

# 2. Installation

# 2.2 Install essential packages
# (needs to run before 2.1)
if ! arch-chroot /mnt pacman -Q base linux linux-firmware &>/dev/null; then
  log "installing essential packages"
  pacstrap /mnt base linux linux-firmware
fi

# 2.1 Select the mirrors
REFLECTOR_CONF_PATH="/mnt/etc/xdg/reflector/reflector.conf"

# install reflector
if ! arch-chroot /mnt pacman -Q reflector &>/dev/null; then
  log "installing reflector"
  arch-chroot /mnt pacman -S --noconfirm reflector
  restart
fi

# configure reflector
if ! (grep -q "--latest 10" "$REFLECTOR_CONF_PATH" && grep -q "--sort rate" "$REFLECTOR_CONF_PATH"); then
  log "configuring reflector"
  sed -i "s/--latest .*/--latest 10" "$REFLECTOR_CONF_PATH"
  sed -i "s/--sort .*/--sort rate" "$REFLECTOR_CONF_PATH"
  arch-chroot /mnt systemctl start reflector.service
fi

# enable timer
if ! arch-chroot /mnt systemctl is-enabled reflector.timer &>/dev/null; then
  log "enabling reflector.timer daemon"
  arch-chroot /mnt systemctl enable reflector.timer
fi
