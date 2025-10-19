#!/bin/bash

echo "g
n
1

+512M
t
1
n
2

+2G
t
2
19

n



w" | fdisk /dev/vda

mkfs.fat -F32 /dev/vda1
mkswap /dev/vda2
swapon /dev/vda2
mkfs.ext4 /dev/vda3

mount /dev/vda3 /mnt
mount --mkdir /dev/vda1 /mnt/boot

pacstrap /mnt base linux linux-firmware

arch-chroot /mnt pacman-key --init
arch-chroot /mnt pacman-key --populate archlinux

genfstab -U /mnt >> /mnt/etc/fstab

echo "Pre-installation complete. Run 'arch-chroot /mnt' and proceed with installation."