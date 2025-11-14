#!/bin/bash

REPO_DIR="/root/tmp/arch-install"
REPO_URL="https://github.com/schnyle/arch-install.git"
APP_LOGFILE="/var/log/arch-install-app.log"
VERBOSE_LOGFILE="/var/log/arch-install-verbose.log"

# === logging setup ===
# (embedded here so bootstrap.sh can log before repo clone)
if [[ -z "$LOGS_REDIRECTED" ]]; then
  # redirect stdout to verbose log
  exec 1> >(tee -a "$VERBOSE_LOGFILE")
  # redirect stderr to app log and verbose log
  exec 2> >(tee -a "$APP_LOGFILE" "$VERBOSE_LOGFILE" >&2)
  export LOGS_REDIRECTED=1
fi

log() {
  local fd=${1:-1}
  shift # remove fd parameter
  msg="$(date '+%Y-%m-%d %H:%M:%S') $*"
  echo "$msg" >&"$fd"

  # stdout doesn't go to app log via exec, so append it manually
  if [[ $fd -eq 1 ]]; then
    echo "$msg" >>"$APP_LOGFILE"
  fi
}

loginfo() {
  log 1 "[INFO] $*"
}

logwarn() {
  log 1 "[WARNING] $*"
}

logerr() {
  log 2 "[ERROR] $*"
}
# === end logging setup ===

make_dirs() {
  if ! mkdir -p /root/tmp; then
    logerr "failed to make directory /root/tmp "
    return 1
  fi

  APP_LOGFILE_DIR=$(dirname $APP_LOGFILE)
  if ! mkdir -p "$APP_LOGFILE_DIR"; then
    logerr "failed to make application log directory $APP_LOGFILE_DIR"
    return 1
  fi

  VERBOSE_LOGFILE_DIR=$(dirname $VERBOSE_LOGFILE)
  if ! mkdir -p "$VERBOSE_LOGFILE_DIR"; then
    logerr "failed to make verbose log directory $VERBOSE_LOGFILE_DIR"
    return 1
  fi
}

init_pacman() {
  if ! pacman-key --init; then
    logerr "failed to initialize pacman keyring"
    return 1
  fi

  if ! pacman-key --populate archlinux; then
    logerr "failed to populate archlinux keyring"
    return 1
  fi

  if ! pacman -Sy --noconfirm; then
    logerr "failed to sync package database"
    return 1
  fi
}

clone_repo() {
  if ! pacman -S --noconfirm git; then
    logerr "failed to install git"
    return 1
  fi

  if [[ -d $REPO_DIR ]]; then
    logwarn "$REPO_DIR exists, removing to allow fresh clone"
    rm -rf $REPO_DIR
  fi

  if ! git clone "$REPO_URL" "$REPO_DIR"; then
    logerr "failed to clone arch-install repository"
    return 1
  fi

  if [[ ! -f "$REPO_DIR/scripts/main.sh" ]]; then
    logerr "arch-install repository clone incomplete - missing scripts/main.sh"
    return 1
  fi

}

if [[ ${BASH_SOURCE[0]} == "$0" && ${#BASH_SOURCE[@]} -eq 1 ]]; then
  loginfo "running arch-install bootstrap"

  loginfo "creating directories"
  make_dirs || exit 1

  loginfo "initializing pacman"
  init_pacman || exit 1

  loginfo "cloning arch-install git repo"
  clone_repo || exit 1

  loginfo "bootstrap complete - running main installation"

  source "$REPO_DIR/scripts/main.sh"
fi
