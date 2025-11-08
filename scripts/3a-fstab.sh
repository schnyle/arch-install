#!/bin/bash

# 3. Configure the sytem (a)

SCRIPTS_DIR="$(dirname "$(realpath "$0")")"
source "$SCRIPTS_DIR/log.sh"

loginfo "starting 3. configure the system (a)"

# 3.1 Fstab
loginfo "generating 'fstab' file"
if ! genfstab -U /mnt >>/mnt/etc/fstab; then
  logerr "error: failed to generate fstab"
  exit 1
fi

if [[ ! -s /mnt/etc/fstab ]]; then
  logerr "error: fstab is empty"
  exit 1
fi

# 3.2 Chroot
# need to implement
