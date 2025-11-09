#!/bin/bash

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
source "$SCRIPT_DIR/../bootstrap.sh"

source "$REPO_DIR/scripts/pacman-install.sh"

loginfo "starting Arch Linux install"

echo
echo "Did you complete steps 1-3.2 manually? (y/n)"
read -r response
[[ "$response" == "n" ]] && FULL_INSTALL=true || FULL_INSTALL=false
loginfo "user responded '$response' to completing steps 1-3.2 manually"

if [[ "$FULL_INSTALL" == "true" ]]; then
  loginfo "performing full installation"

  loginfo "running 1-pre-installation.sh"
  bash "$REPO_DIR"/scripts/1-pre-installation.sh

  loginfo "running 2-installation.sh"
  bash "$REPO_DIR"/scripts/2-installation.sh

  loginfo "running 3a-fstab.sh"
  bash "$REPO_DIR"/scripts/3a-fstab.sh

  loginfo "creating /mnt/root/tmp/ directory"
  mkdir -p /mnt/root/tmp

  loginfo "copying arch-install repo into /mnt"
  cp -r "$REPO_DIR" /mnt/root/tmp/
  find /mnt/root/tmp/arch-install/ -type f -name "*.sh" -exec chmod +x {} +

  loginfo "copying log files into /mnt"
  cp $APP_LOGFILE /mnt/var/log
  cp $VERBOSE_LOGFILE /mnt/var/log

  loginfo "chroot'ing into /mnt"
  arch-chroot /mnt bash /root/tmp/arch-install/scripts/3b-configure-the-system.sh
else
  loginfo "performing chroot installation"
  bash "$REPO_DIR"/scripts/3b-configure-the-system.sh
fi

loginfo "configuring post-installation auto-run on next reboot"
source "$REPO_DIR/scripts/auto-run-post-installation.sh"

bash "$REPO_DIR/scripts/4-reboot.sh"
