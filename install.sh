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

echo "~~~Installing Arch Linux~~~"

# assumes steps 1., 2., 3.1, 3.2 are already completed

# 3.8 boot loader
echo "Setting up GRUB boot loader"
pacman -S --noconfirm grub efibootmgr os-prober
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

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

# ~~~ 4. custom installation ~~~

# 4.1 create a user


packages_to_install=(
  "alacritty"
  "arandr"
  "waaah"
  "base-devel"
  "bbc-fake-package"
  "cmake"
)

echo "Installing ${#packages_to_install[@]} pacman packages"
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

