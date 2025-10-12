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

pacman -S --noconfirm sudo

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
echo "Creating new wheel user"
while true; do
  echo "New username:"
  read -r username
  if [[ -z "$username" ]]; then
    echo "Error: Username cannot be empty"
    continue
  fi
  
  if useradd -m -G wheel "$username"; then
    break
  else
    echo "Error: Failed to create user '$username'. Please try a different username."
  fi
done

while true; do
  if passwd "$username"; then
    break
  fi
done

sed -i "s/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/" /etc/sudoers

# 4.2 setup networking daemon
echo "Setting up networking"
pacman -S --noconfirm networkmanager
systemctl enable NetworkManager

# 4.3 install pacman packages

packages_to_install=(
  "alacritty"
  "arandr"
  "waaah"
  "base-devel"
  "bbc-fake-package"
  "cmake"
  "vim"
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
