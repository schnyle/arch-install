#!/bin/bash

# configuration
pacman_packages_filename="packages_test"
GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"
verbose=false

# parse command line arguments

for arg in "$@"; do
  case $arg in 
    -v)
      verbose=true
      ;;
  esac
done

install_pacman_packages() {
  failed=()
  for package in "$@"; do
    if output=$(sudo pacman -S --noconfirm "$package" 2>&1); then
      echo -e "$package: [${GREEN}success${RESET}]"
      if [[ $verbose == true ]]; then
        echo "$output"
      fi
    else
      echo -e "$package: [${RED}failed${RESET}]"
      echo "$output"
      failed+=("$package")
    fi      
  done
}

echo "~~~Installing Arch Linux~~~"

mapfile -t PACMANPACKAGES < "$pacman_packages_filename"
echo "Installing ${#PACMANPACKAGES[@]} pacman packages"

packages_to_install=("${PACMANPACKAGES[@]}")

while true; do 
  install_pacman_packages "${packages_to_install[@]}"

  [ ${#failed[@]} -eq 0 ] && break

  echo ""
  echo "Failed pacman packages: ${failed[*]}"
  echo "Retry? (y/n)"
  read -r retry
  [[ $retry != "y" ]] && break
  
  packages_to_install=("${failed[@]}")
done

