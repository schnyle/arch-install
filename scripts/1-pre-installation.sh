#!/bin/bash

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source "$SCRIPT_DIR/../bootstrap.sh"

BOOT_SIZE="512M"
SWAP_SIZE="2G"

get_device_from_user() {
  while true; do
    echo "available devices:"
    lsblk -d -o NAME,SIZE,TYPE | grep disk

    echo
    echo "enter device name (omit '/dev/'):"
    read -r device

    if [[ -b "/dev/$device" ]]; then
      loginfo "user selected '$device' for disk device"
      break
    else
      logwarn "device '$device' not found, try again"
    fi
  done
}

create_partitions() {
  sfdisk "/dev/$device" <<EOF
label: gpt
,$BOOT_SIZE,U
,$SWAP_SIZE,S
,,L
write
EOF

  if [[ ! -b "$boot_partition" ]]; then
    logerr "boot partition not created"
    return 1
  fi
  if [[ ! -b "$swap_partition" ]]; then
    logerr "swap partition not created"
    return 1
  fi
  if [[ ! -b "$root_partition" ]]; then
    logerr "root partition not created"
    return 1
  fi
}

format_partitions() {
  if ! mkfs.fat -F32 "$boot_partition"; then
    logerr "failed to format boot partition"
    return 1
  fi

  if ! mkswap "$swap_partition"; then
    logerr "failed to create swap"
    return 1
  fi

  if ! swapon "$swap_partition"; then
    logerr "failed to enable swap"
    return 1
  fi

  if ! mkfs.ext4 "$root_partition"; then
    logerr "failed to format root partition"
    return 1
  fi
}

mount_partitions() {
  if ! mount "$root_partition" /mnt; then
    logerr "failed to mount root partition"
    return 1
  fi

  if ! mount --mkdir "$boot_partition" /mnt/boot; then
    logerr "failed to mount boot partition"
    return 1
  fi
}

# steps 1.1 - 1.7 assumed to be completed by user

loginfo "1.8 Update the system clock"
if ! timedatectl; then
  logwarn "failed to update the system clock"
fi

loginfo "1.9 Partition the disks"
loginfo "getting disk device name from user"
get_device_from_user

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

loginfo "partitioning the disks"
if ! create_partitions; then
  logerr "failed to create disk partitions"
  exit 1
fi

loginfo "formatting the partitions"
if ! format_partitions; then
  logerr "failed to format the partitions"
  exit 1
fi

loginfo "1.11 Mount the file systems"
if ! mount_partitions; then
  logerr "failed to mount the file systems"
  exit 1
fi
