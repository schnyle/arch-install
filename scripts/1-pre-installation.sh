#!/bin/bash

# Arch installation Guide Step 1
# steps 1.1 - 1.7 assumed to be completed by user

while true; do
  echo "available devices:"
  lsblk -d -o NAME,SIZE,TYPE | grep disk
  echo "enter device name (omit '/dev/'):"
  read -r device

  if [[ -b "/dev/$device" ]]; then
    break
  else
    echo "device not found, try again"
  fi
done

# 1.8 Update the system clock
timedatectl

# 1.9 Partition the disks
sfdisk "/dev/$device" <<EOF
label: gpt
,512M,U
,2G,S
,,L
EOF

if [[ ! -b "/dev/${device}1" ]]; then
  echo "Error: Boot partition not created"
  exit 1
fi
if [[ ! -b "/dev/${device}2" ]]; then
  echo "Error: Swap partition not created"
  exit 1
fi
if [[ ! -b "/dev/${device}3" ]]; then
  echo "Error: Root partition not created"
  exit 1
fi

# 1.10 Format the partitions
if ! mkfs.fat -F32 "/dev/${device}1"; then
  echo "Error: Failed to format boot partition"
  exit 1
fi

if ! mkswap "/dev/${device}2"; then
  echo "Error: Failed to create swap"
  exit 1
fi

if ! swapon "/dev/${device}2"; then
  echo "Error: Failed to enable swap"
  exit 1
fi

if ! mkfs.ext4 "/dev/${device}3"; then
  echo "Error: Failed to format root partition"
  exit 1
fi

# 1.11 Mount the file systems
if ! mount "/dev/${device}3" /mnt; then
  echo "Error: Failed to mount root partition"
  exit 1
fi

if ! mount --mkdir "/dev/${device}1" /mnt/boot; then
  echo "Error: Failed to mount boot partition"
  exit 1
fi
