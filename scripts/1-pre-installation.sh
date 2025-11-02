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

# 1.9 Partition the disks
loginfo "partitioning the disks"
sfdisk "/dev/$device" <<EOF
label: gpt
,512M,U
,2G,S
,,L
write
EOF

if [[ ! -b "/dev/${device}1" ]]; then
  logerr "boot partition not created"
  exit 1
fi
if [[ ! -b "/dev/${device}2" ]]; then
  logerr "swap partition not created"
  exit 1
fi
if [[ ! -b "/dev/${device}3" ]]; then
  logerr "root partition not created"
  exit 1
fi

# 1.10 Format the partitions
loginfo "formatting the partitions"
if ! mkfs.fat -F32 "/dev/${device}1"; then
  logerr "failed to format boot partition"
  exit 1
fi

if ! mkswap "/dev/${device}2"; then
  logerr "failed to create swap"
  exit 1
fi

if ! swapon "/dev/${device}2"; then
  logerr "failed to enable swap"
  exit 1
fi

if ! mkfs.ext4 "/dev/${device}3"; then
  logerr "failed to format root partition"
  exit 1
fi

# 1.11 Mount the file systems
loginfo "mounting the file systems"
if ! mount "/dev/${device}3" /mnt; then
  logerr "failed to mount root partition"
  exit 1
fi

if ! mount --mkdir "/dev/${device}1" /mnt/boot; then
  logerr "failed to mount boot partition"
  exit 1
fi
