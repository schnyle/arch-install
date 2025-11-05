#!/bin/bash

echo "[INFO] cloning arch-install git repo"
mkdir -p /root/tmp
REPO_DIR="/root/tmp/arch-install"

if ! pacman -Sy --noconfirm; then
  echo "[ERROR] failed to sync package database" >&2
  exit 1
fi

if ! pacman -S --noconfirm git; then
  echo "[ERROR] failed to install git" >&2
  exit 1
fi

if [[ -d $REPO_DIR ]]; then
  echo "[WARNING] $REPO_DIR exists, removing to allow fresh clone"
  rm -rf $REPO_DIR
fi

if ! git clone https://github.com/schnyle/arch-install.git $REPO_DIR; then
  echo "[ERROR] failed to clone arch-install repository" >&2
  exit 1
fi

if [[ ! -f "$REPO_DIR/scripts/helpers/log.sh" ]]; then
  echo "[ERROR] arch-install repository clone incomplete - missing log.sh" >&2
  exit 1
fi

echo "[INFO] successfully cloned arch-install git repo"

echo "[INFO] sourcing helper scripts"
source "$REPO_DIR/scripts/helpers/log.sh"
source "$REPO_DIR/scripts/helpers/pacman-install.sh"

loginfo "starting Arch Linux install"

if [[ "$1" == "--full" ]]; then
  FULL_INSTALL=true
elif [[ "$1" == "--chroot" ]]; then
  FULL_INSTALL=false
else
  echo
  echo "Did you complete steps 1-3.2 manually? (y/n)"
  read -r response
  loginfo "user responded '$response' to completing steps 1-3.2 manually"
  [[ "$response" == "n" ]] && FULL_INSTALL=true || FULL_INSTALL=false
fi

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

  loginfo "copying log files into /mnt"
  cp /var/log/arch-install.log /mnt/var/log
  cp /var/log/arch-install-verbose.log /mnt/var/log

  loginfo "chroot'ing into /mnt"
  arch-chroot /mnt bash /root/tmp/arch-install/scripts/3b-configure-the-system.sh
else
  loginfo "performing chroot installation"
  bash "$REPO_DIR"/scripts/3b-configure-the-system.sh
fi

bash "$REPO_DIR/scripts/4-reboot.sh"
