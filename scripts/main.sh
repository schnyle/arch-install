#!/bin/bash

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source "$SCRIPT_DIR/../bootstrap.sh"

source "$REPO_DIR/scripts/pacman-install.sh"

copy_repo_to_mount() {
  if ! mkdir -p /mnt/root/tmp; then
    logerr "failed to make directory /mnt/root/tmp"
    return 1
  fi

  if ! cp -r "$REPO_DIR" /mnt/root/tmp/; then
    logerr "failed to copy repo to /mnt/root/tmp"
    return 1
  fi

  if ! find /mnt/root/tmp/arch/ -type f -name "*.sh" -exec chmod +x {} +; then
    logerr "failed to make repo scripts executable"
    return 1
  fi
}

loginfo "starting Arch Linux install"

if ! mountpoint -q /mnt; then
  loginfo "no mount detected at /mnt, running 1. Pre-installation"
  source "$REPO_DIR"/scripts/1-pre-installation.sh
fi

loginfo "copying arch repo into /mnt"
if ! copy_repo_to_mount; then
  logerr "failed to copy arch repo into /mnt"
  exit 1
fi

loginfo "running 2. Installation"
source "$REPO_DIR"/scripts/2-installation.sh

loginfo "running 3. Configure the system"
source "$REPO_DIR"/scripts/3-configure-the-system.sh

loginfo "configuring post-installation auto-run on next reboot"
source "$REPO_DIR/scripts/auto-run-post-installation.sh"

loginfo "copying log files into /mnt"
cp "$APP_LOGFILE" /mnt/var/log || logwarn "failed to copy application log"
cp "$VERBOSE_LOGFILE" /mnt/var/log || logwarn "failed to copy verbose log"

loginfo "running 4. Reboot"
source "$REPO_DIR/scripts/4-reboot.sh"
