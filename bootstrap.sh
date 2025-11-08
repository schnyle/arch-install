#!/bin/bash

export REPO_DIR="/root/tmp/arch-install"

REPO_URL="https://github.com/schnyle/arch-install.git"

echo ""

if [[ ${BASH_SOURCE[0]} == "$0" && ${#BASH_SOURCE[@]} -eq 1 ]]; then
  echo "[INFO] running arch-install bootstrap"

  mkdir -p /root/tmp
  echo "[INFO] arch-install repo dir: $REPO_DIR"

  echo "[INFO] cloning arch-install git repo"
  if ! pacman-key --init; then
    echo "[ERROR] failed to initialize pacman keyring" 2>&1
    exit 1
  fi

  if ! pacman-key --populate archlinux; then
    echo "[ERROR] failed to populate archlinux keyring" 2>&1
    exit 1
  fi

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

  if ! git clone "$REPO_URL" "$REPO_DIR"; then
    echo "[ERROR] failed to clone arch-install repository" >&2
    exit 1
  fi

  if [[ ! -f "$REPO_DIR/scripts/main.sh" ]]; then
    echo "[ERROR] arch-install repository clone incomplete - missing scripts/main.sh" >&2
    exit 1
  fi

  echo "[INFO] successfully cloned arch-install git repo"

  echo "[INFO] bootstrap complete"

  source "$REPO_DIR/scripts/main.sh"
fi
