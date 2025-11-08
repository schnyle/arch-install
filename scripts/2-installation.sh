#!/bin/bash

# 2. Installation

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
source "$SCRIPT_DIR/../bootstrap.sh"

loginfo "start 2. installation"

# 2.1 Select the mirrors
# will add code here
# reflector --country US --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# 2.2 Install essential packages
loginfo "installing essential packages with pacstrap"
attempt=0
while true; do
  ((attempt++))
  if pacstrap /mnt base linux linux-firmware networkmanager; then
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
