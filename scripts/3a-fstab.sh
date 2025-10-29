#!/bin/bash

# 3.1 Fstab
if ! genfstab -U /mnt >>/mnt/etc/fstab; then
  echo "error: failed to generate fstab"
  exit 1
fi

if [[ ! -s /mnt/etc/fstab ]]; then
  echo "error: fstab is empty"
  exit 1
fi

# 3.2 Chroot
# need to implement
