#!/bin/bash

# 2.1 Select the mirrors
# will add code here
# reflector --country US --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# 2.2 Install essential packages
pacstrap /mnt base linux linux-firmware networkmanager

# rest will be moved to main install.sh scripts
arch-chroot /mnt pacman-key --init
arch-chroot /mnt pacman-key --populate archlinux
