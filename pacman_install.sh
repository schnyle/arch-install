#!/bin/bash

DEFAULT_ATTEMPTS=3

log() {
  echo "[ARCH-INSTALL] $*"
}

pacman_batch() {
  packages="$@"
  log "installing ${#packages[@]} pacman packages: $*"

  failed_packages=()
  if pacman -S --noconfirm "$@"; then
    log "successfully installed ${#packages[@]} pacman packages"
    return 0
  else
    log "batch pacman install failed, installing individually"
    for package in "$@"; do
      if ! pacman_single "$package"; then
        failed_packages+=("$package")
      fi
    done
  fi

  if [[ ${#failed_packages[@]} -gt 0 ]]; then
    log "Failed to install ${#failed_packages[@]} packages: ${failed_packages[*]}"
  fi

  return ${#failed_packages[@]}
}

pacman_single() {
  package="$@"
  log "installing single pacman package $package"

  attempt=0
  while true; do
    attempt=$((attempt + 1))

    if pacman -S --noconfirm "$package"; then
      log "successfully installed pacman package $package"
      return 0
    fi

    log "failed to install pacman package $package"

    if ((attempt < DEFAULT_ATTEMPTS)); then
      log "retrying installation of pacman package $package (attempt $((attempt + 1))/$DEFAULT_ATTEMPTS)"
      continue
    fi

    echo "Failed to install $package ($attempt attempts). Try again? (y/n)"
    read -r retry
    if [[ $retry == "y" ]]; then
      log "user chose to retry installation of pacman package $package (attempt $attempt)"
      continue
    else
      log "user chose to skip installation of pacman package $package"
      return 1
    fi
  done
}
