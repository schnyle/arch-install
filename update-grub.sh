#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Must run as root"
  exit 1
fi

MOUNT_DIR="/tmp/mnt"

# Clean up mount directory
if [ -d "$MOUNT_DIR" ]; then
  for mnt in $(mount | grep "$MOUNT_DIR" | awk '{print $3}' | sort -r); do
    umount -l "$mnt" 2>/dev/null
  done

  rm -rf "$MOUNT_DIR"
fi

mkdir -p "$MOUNT_DIR"

# Get partitions (exclude full drives and loops)
PARTITIONS=$(lsblk -lnp -o NAME,TYPE | grep "part" | grep -v "loop" | awk '{print $1}')

MOUNT_COUNT=0

# Mount partitions
echo "Mounting system partitions..." 
for PART in $PARTITIONS; do
  if mount | grep -q "$PART "; then
    continue
  fi

  PART_DIR="$MOUNT_DIR/$(basename $PART)"
  mkdir -p "$PART_DIR"

  if mount "$PART" "$PART_DIR" 2>/dev/null; then
    ((MOUNT_COUNT++))
  else
    echo "Could not mount $PART"
    rmdir "$PART_DIR"
  fi
done

echo "Mounted $MOUNT_COUNT partitions"

echo "Running grub-mkconfig..."
grub-mkconfig -o /boot/grub/grub.cfg

# Unmount partitions
for mnt in $(mount | grep "$MOUNT_DIR" | awk '{print $3}' | sort -r); do
  umount "$mnt" || umount -l "$mnt"
done


rm -rf "$MOUNT_DIR"