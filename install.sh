#!/bin/bash

# log output
exec > >(tee /var/log/arch-install.log) 2>&1

echo "cloning arch-install git repo"
mkdir -p /root/tmp
REPO_DIR="/root/tmp/arch-install"

if ! pacman -Sy --noconfirm; then
  echo "Error: failed to sync package database" >&2
  exit 1
fi

if ! pacman -S --noconfirm git; then
  echo "Error: failed to install git" >&2
  exit 1
fi

if ! git clone https://github.com/schnyle/arch-install.git $REPO_DIR; then
  echo "Error: failed to clone arch-install repository" >&2
  exit 1
fi

# verify git clone
if [[ ! -f "$REPO_DIR/scripts/helpers/log.sh" ]]; then
  echo "Error: arch-install repository clone incomplete - missing log.sh" >&2
  exit 1
fi

source "$REPO_DIR/scripts/helpers/log.sh"
log "starting Arch Linux install"

if [[ "$1" == "--full" ]]; then
  FULL_INSTALL=true
elif [[ "$1" == "--chroot" ]]; then
  FULL_INSTALL=false
else
  echo "Did you complete steps 1-3.2 manually? (y/n)"
  read -r response
  [[ "$response" == "n" ]] && FULL_INSTALL=true || FULL_INSTALL=false
fi

if [[ "$FULL_INSTALL" == "true" ]]; then
  log "performing full installation"
  bash "$REPO_DIR"/scripts/1-pre-installation.sh
  bash "$REPO_DIR"/scripts/2-installation.sh
  bash "$REPO_DIR"/scripts/3a-fstab.sh

  mkdir -p /mnt/root/tmp
  cp -r "$REPO_DIR" /mnt/root/tmp/
  arch-chroot /mnt bash /root/tmp/arch-install/scripts/3b-configure-the-system.sh
  bash "$REPO_DIR/scripts/4-reboot.sh"

  log "exiting chroot, unmounting filesystems and rebooting"
  umount -R /mnt
  reboot
else
  log "performing chroot installation"
  bash "$REPO_DIR"/scripts/3b-configure-the-system.sh
  bash "$REPO_DIR"/scripts/4-reboot.sh

  log "rebooting system"
  reboot
fi
