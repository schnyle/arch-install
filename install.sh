#!/bin/bash

GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"

echo "~~~Installing Arch Linux~~~"

# assumes steps 1., 2., 3.1, 3.2 are already completed

pacman -S --noconfirm sudo

# 3.3 time
ln -sf /usr/share/zoneinfo/America/Denver /etc/localtime
hwclock --systohc

# 3.4 localization
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
touch /etc/locale.conf
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# 3.5 network configuration
while true; do
  echo "System hostname:"
  read -r hostname
  if echo "$hostname" > /etc/hostname; then
    break
  fi
done

# 3.6 initramfs
# usually not required

# 3.7 set root password
echo "Setting password for root"
while true; do
  if passwd; then
    break
  fi
done

# 3.8 boot loader
pacman -S --noconfirm grub efibootmgr os-prober
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

install_pacman_packages() {
  failed=()
  for package in "$@"; do
    if output=$(sudo pacman -S --noconfirm "$package" 2>&1); then
      echo -e "$package: [${GREEN}success${RESET}]"
        echo "$output"
    else
      echo -e "$package: [${RED}failed${RESET}]"
      echo "$output"
      failed+=("$package")
    fi      
  done
}

# ~~~ 4. custom installation ~~~

# 4.1 user setup

# 4.1.1 create new user
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

# 4.1.2 setup oh-my-zsh

pacman -S --noconfirm zsh
sudo -u "$username" bash -c "curl -L https://install.ohmyz.sh | sh"
sudo -u "$username" chsh -s /usr/bin/zsh

# 4.1.3 collect user preferences
echo "Install NVIDIA drivers? (y/n)"
read -r install_nvidia

# 4.2 networking daemon
pacman -S --noconfirm networkmanager
systemctl enable NetworkManager

# 4.3 graphics/ui 

# 4.3.1 X11
pacman -S --noconfirm xorg-server xorg-xinit xorg-apps

# 4.3.2 window manager, fonts, compositor 
pacman -S --noconfirm i3
mkdir /usr/share/fonts
cp /tmp/arch-install/fonts/*.ttf /usr/share/fonts/
fc-cache -fv
if systemd-detect-virt -q; then
  echo "VM detected, skipping compositor"
else
  pacman -S --noconfirm picom
fi

# 4.3.3 display configuration
pacman -S --noconfirm arandr
ln -sf /usr/bin/arandr /usr/local/bin/displays

# 4.3.4 NVIDIA drivers
if [[ $install_nvidia == "y" ]]; then
  pacman -S --noconfirm nvidia nvidia-utils nvidia-settings
fi

# 4.4 install pacman packages

packages_to_install=(
  "alacritty"  
  "base-devel"
  "cmake"
  "vim"
  "man-db"
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

# 4.5 dotfiles
pacman -S --noconfirm stow
sudo -u "$username" git clone https://github.com/schnyle/dotfiles.git /home/$username/.dotfiles
sudo -u "$username" bash /home/$username/.dotfiles/install.sh