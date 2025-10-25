#!/bin/bash

# log output
exec > >(tee /var/log/arch-install.log) 2>&1

echo "cloning arch-install git repo"
REPO_DIR="/tmp/arch-install"
pacman -Sy
pacman -S --noconfirm git
git clone https://github.com/schnyle/arch-install.git $REPO_DIR

#ARCH_INSTALL_DIR="$(dirname "$(realpath "$0")")"
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
  cp -r "$REPO_DIR"/scripts/ /mnt/tmp/
  arch-chroot /mnt /bin/bash -i /tmp/scripts/3b-configure-the-system.sh
  arch-chroot /mnt /bin/bash -i /tmp/scripts/4-reboot.sh
  #arch-chroot /mnt bash "$ARCH_INSTALL_DIR"/scripts/3b-system-configuration.sh
  #arch-chroot /mnt bash "$ARCH_INSTALL_DIR"/scripts/4-post-installation.sh
else
  log "performing chroot installation"
  bash "$REPO_DIR"/scripts/3b-configure-the-system.sh
  bash "$REPO_DIR"/scripts/4-reboot.sh
fi

#okay, and then the two branches meetup with 4-reboot. we should exit chroot, unmount the file system, and then reboot the system. but we need to set it up to
