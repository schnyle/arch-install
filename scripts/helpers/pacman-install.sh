#!/bin/bash

HELPERS_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source "$HELPERS_DIR/log.sh"

DEFAULT_ATTEMPTS=3

pacmansync() {
  if [[ $# -eq 0 ]]; then
    logwarn "pacmansync() called but no packages given"
    return 0
  fi

  loginfo "installing $# pacman packages: $*"

  failed_packages=()
  if pacman -S --noconfirm "$@"; then
    loginfo "successfully installed $# pacman packages"
    return 0
  else
    logwarn "batch pacman install failed, installing individually"
    for package in "$@"; do
      if ! pacman_single "$package"; then
        failed_packages+=("$package")
      fi
    done
  fi

  if [[ ${#failed_packages[@]} -gt 0 ]]; then
    logerr "failed to install ${#failed_packages[@]} packages: ${failed_packages[*]}"
  fi

  return ${#failed_packages[@]}
}

pacman_single() {
  package="$1"
  loginfo "installing single pacman package $package"

  attempt=0
  while true; do
    attempt=$((attempt + 1))

    if pacman -S --noconfirm "$package"; then
      loginfo "successfully installed pacman package $package"
      return 0
    fi

    logerr "failed to install pacman package $package"

    if ((attempt < DEFAULT_ATTEMPTS)); then
      loginfo "retrying installation of pacman package $package (attempt $((attempt + 1))/$DEFAULT_ATTEMPTS)"
      continue
    fi

    echo
    echo "Failed to install $package ($attempt attempts). Try again? (y/n)"
    read -r retry
    if [[ $retry == "y" ]]; then
      loginfo "user chose to retry installation of pacman package $package (attempt $attempt)"
      continue
    else
      loginfo "user chose to skip installation of pacman package $package"
      return 1
    fi
  done
}
