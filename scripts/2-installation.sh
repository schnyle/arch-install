#!/bin/bash

# 2. Installation

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source "$SCRIPT_DIR/../bootstrap.sh"

loginfo "start 2. installation"

# 2.1 Select the mirrors
# use default mirrorlist for initial installation
# reflector.service is setup in the post-installation script

# 2.2 Install essential packages
loginfo "installing essential packages with pacstrap"
attempt=0
while true; do
  ((attempt++))
  if pacstrap /mnt base linux linux-firmware sudo networkmanager; then
    break
  else
    echo "pacstrap failed (attempt $attempt). Retry? (y/n)"
    read -r retry
    if [[ "$retry" != "y" ]]; then
      logerr "could not install essential packages - installation aborted"
      exit 1
    fi
  fi
done

arch-chroot /mnt systemctl enable NetworkManager
