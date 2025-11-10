#!/bin/bash

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source "$SCRIPT_DIR/../bootstrap.sh"

source "$REPO_DIR/scripts/pacman-install.sh"

loginfo "starting Arch Linux install"

if ! mountpoint -q /mnt; then
  loginfo "no mount detected at /mnt, running pre installation"
  bash "$REPO_DIR"/scripts/1-pre-installation.sh
fi

loginfo "running 2-installation.sh"
bash "$REPO_DIR"/scripts/2-installation.sh

loginfo "copying arch-install repo into /mnt"
mkdir -p /mnt/root/tmp
cp -r "$REPO_DIR" /mnt/root/tmp/
find /mnt/root/tmp/arch-install/ -type f -name "*.sh" -exec chmod +x {} +

loginfo "running 3-configure-the-system.sh"
bash "$REPO_DIR"/scripts/3-configure-the-system.sh

loginfo "copying log files into /mnt"
cp $APP_LOGFILE /mnt/var/log
cp $VERBOSE_LOGFILE /mnt/var/log

loginfo "configuring post-installation auto-run on next reboot"
source "$REPO_DIR/scripts/auto-run-post-installation.sh"

bash "$REPO_DIR/scripts/4-reboot.sh"
