#!/bin/bash

# Arch installation Guide Step 1
# steps 1.1 - 1.7 assumed to be completed by user

# 1.8 Update the system clock
timedatectl

# 1.9 Partition the disks
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

# 1.10 Format the partitions
mkfs.fat -F32 /dev/vda1
mkswap /dev/vda2
swapon /dev/vda2
mkfs.ext4 /dev/vda3

# 1.11 Mount the file systems
mount /dev/vda3 /mnt
mount --mkdir /dev/vda1 /mnt/boot
