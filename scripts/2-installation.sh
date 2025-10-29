#!/bin/bash

# 2.1 Select the mirrors
# will add code here
# reflector --country US --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# 2.2 Install essential packages
attempt=0
while true; do
  ((attempt++))
  if pacstrap /mnt base linux linux-firmware networkmanager; then
    break
  else
    echo "pacstrap failed (attempt $attempt). Retry? (y/n)"
    read -r retry
    if [[ "$retry" != "y" ]]; then
      echo "installation aborted"
      exit 1
    fi
  fi
done

# rest will be moved to main install.sh scripts
if ! arch-chroot /mnt pacman-key --init; then
  echo "error: failed to initialize pacman keys"
  exit 1
fi

if ! arch-chroot /mnt pacman-key --populate archlinux; then
  echo "error: failed to populate pacman keys"
  exit 1
fi
