#!/bin/bash

# 1. Pre-installation

SCRIPTS_DIR="$(dirname "$(realpath "$0")")"
source "$SCRIPTS_DIR/helpers/log.sh"

loginfo "starting 1. pre-installation"

# steps 1.1 - 1.7 assumed to be completed by user

# 1.8 Update the system clock
timedatectl

# 1.9 Partition the disks
loginfo "getting disk device name from user"
while true; do
  prompt "available devices:"
  lsblk -d -o NAME,SIZE,TYPE | grep disk

  prompt "enter device name (omit '/dev/'):"
  read -r device

  if [[ -b "/dev/$device" ]]; then
    loginfo "user selected '$device' for disk device"
    break
  else
    logerr "device not found, try again"
  fi
done

# determine partition suffix based on device type
if [[ "$device" == nvme* ]]; then
  suffix="p"
else
  suffix=""
fi

boot_partition="/dev/${device}${suffix}1"
loginfo "using $boot_partition for boot partition"

swap_partition="/dev/${device}${suffix}2"
loginfo "using $swap_partition for swap partition"

root_partition="/dev/${device}${suffix}3"
loginfo "using $root_partition for root partition"

# 1.9 Partition the disks
loginfo "partitioning the disks"
sfdisk "/dev/$device" <<EOF
label: gpt
,512M,U
,2G,S
,,L
write
EOF

if [[ ! -b "$boot_partition" ]]; then
  logerr "boot partition not created"
  exit 1
fi
if [[ ! -b "$swap_partition" ]]; then
  logerr "swap partition not created"
  exit 1
fi
if [[ ! -b "$root_partition" ]]; then
  logerr "root partition not created"
  exit 1
fi

# 1.10 Format the partitions
loginfo "formatting the partitions"
if ! mkfs.fat -F32 "$boot_partition"; then
  logerr "failed to format boot partition"
  exit 1
fi

if ! mkswap "$swap_partition"; then
  logerr "failed to create swap"
  exit 1
fi

if ! swapon "$swap_partition"; then
  logerr "failed to enable swap"
  exit 1
fi

if ! mkfs.ext4 "$root_partition"; then
  logerr "failed to format root partition"
  exit 1
fi

# 1.11 Mount the file systems
loginfo "mounting the file systems"
if ! mount "$root_partition" /mnt; then
  logerr "failed to mount root partition"
  exit 1
fi

if ! mount --mkdir "$boot_partition" /mnt/boot; then
  logerr "failed to mount boot partition"
  exit 1
fi
