#!/bin/bash

REPO_DIR="/root/tmp/arch-install"
REPO_URL="https://github.com/schnyle/arch-install.git"
APP_LOGFILE="/var/log/arch-install-app.log"
VERBOSE_LOGFILE="/var/log/arch-install-verbose.log"

# === logging setup ===
# (embedded here so bootstrap can log before repo clone)

# redirect all output to verbose log
if [[ -z "$LOGS_REDIRECTED" ]]; then
  exec > >(tee -a "$VERBOSE_LOGFILE") 2>&1
  export LOGS_REDIRECTED=1
fi

log() {
  msg="$(date '+%Y-%m-%d %H:%M:%S') $*"
  echo "$msg"                  # verbose logfile
  echo "$msg" >>"$APP_LOGFILE" # application logfile
}

loginfo() {
  log "[INFO] $*"
}

logwarn() {
  log "[WARNING] $*"
}

logerr() {
  log "[ERROR] $*"
}
# === end logging setup ===

if [[ ${BASH_SOURCE[0]} == "$0" && ${#BASH_SOURCE[@]} -eq 1 ]]; then
  loginfo "running arch-install bootstrap"

  mkdir -p /root/tmp
  loginfo "arch-install repo dir: $REPO_DIR"

  loginfo "cloning arch-install git repo"
  if ! pacman-key --init; then
    logerr "failed to initialize pacman keyring" 2>&1
    exit 1
  fi

  if ! pacman-key --populate archlinux; then
    logerr "failed to populate archlinux keyring" 2>&1
    exit 1
  fi

  if ! pacman -Sy --noconfirm; then
    logerr "failed to sync package database" >&2
    exit 1
  fi

  if ! pacman -S --noconfirm git; then
    logerr "failed to install git" >&2
    exit 1
  fi

  if [[ -d $REPO_DIR ]]; then
    logwarn "$REPO_DIR exists, removing to allow fresh clone"
    rm -rf $REPO_DIR
  fi

  if ! git clone "$REPO_URL" "$REPO_DIR"; then
    logerr "failed to clone arch-install repository" >&2
    exit 1
  fi

  if [[ ! -f "$REPO_DIR/scripts/main.sh" ]]; then
    logerr "arch-install repository clone incomplete - missing scripts/main.sh" >&2
    exit 1
  fi

  loginfo "successfully cloned arch-install git repo"
  loginfo "bootstrap complete"

  source "$REPO_DIR/scripts/main.sh"
fi
