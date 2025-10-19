#!/bin/bash

ARCH_INSTALL_DIR="$(dirname "$(realpath "$0")")"
source "$ARCH_INSTALL_DIR/pacman_install.sh"

# log output
exec > >(tee /var/log/arch-install.log) 2>&1

log() {
  echo "[ARCH-INSTALL] $*"
}

log "starting Arch Linux install"

# assumes steps 1., 2., 3.1, 3.2 are already completed

#sync package database after chroot
pacman -Sy

pacman_single "sudo"

# 3.3 time
ln -sf /usr/share/zoneinfo/America/Denver /etc/localtime
hwclock --systohc

# 3.4 localization
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
touch /etc/locale.conf
echo "LANG=en_US.UTF-8" >/etc/locale.conf

# 3.5 network configuration
while true; do
  echo "System hostname:"
  read -r hostname
  if echo "$hostname" >/etc/hostname; then
    break
  fi
done

# 3.6 initramfs
# usually not required

# 3.7 set root password
log "Setting password for root"
while true; do
  if passwd; then
    break
  fi
done

# 3.8 boot loader
pacman_batch "grub" "efibootmgr" "os-prober"
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# ~~~ 4. custom installation ~~~

# 4.1 user setup

# 4.1.1 create new user
log "Creating new wheel user"
while true; do
  echo "New username:"
  read -r username
  if [[ -z "$username" ]]; then
    log "Error: Username cannot be empty"
    continue
  fi

  if useradd -m -G wheel "$username"; then
    break
  else
    log "Error: Failed to create user '$username'. Please try a different username."
  fi
done

while true; do
  if passwd "$username"; then
    break
  fi
done

sed -i "s/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/" /etc/sudoers

# 4.1.2 oh-my-zsh

pacman_single "zsh"
sudo -u "$username" bash -c "curl -L https://install.ohmyz.sh | sh"
sudo -u "$username" chsh -s /usr/bin/zsh

# 4.1.3 enable pulse audio
mkdir -p /home/$username/.config/systemd/user/default.target.wants
ln -sf /usr/lib/systemd/user/pulseaudio.service /home/$username/.config/systemd/user/default.target.wants/
chown -R $username:$username /home/$username/.config

# 4.1.4 install Arch User Repository helper
log "installing yay"
pacman_batch "git" "base-devel"
git clone https://aur.archlinux.org/yay.git /opt/yay
chown -R $username:$username /opt/yay
sudo -u "$username" makepkg -si -D /opt/yay --noconfirm

# 4.1.5 collect user preferences
echo "Install NVIDIA drivers? (y/n)"
read -r install_nvidia

# 4.2 first-party software

ARCH_INSTALL_DIR="$(dirname "$(realpath "$0")")"
PACMAN_PACKAGES_FILE_PATH="$ARCH_INSTALL_DIR/pacman-packages"

packages=()
while IFS= read -r line; do
  line="${line%%#*}"
  line=$(echo "$line" | xargs)

  [[ -z "$line" ]] && continue

  packages+=("$line")
done <"$PACMAN_PACKAGES_FILE_PATH"

log "Installing ${#packages[@]} pacman packages"
pacman_batch "${packages[@]}"

# 4.3 networking daemon
systemctl enable NetworkManager

# 4.4 graphics/ui

# 4.4.1 fonts
mkdir /usr/share/fonts
cp /tmp/arch-install/fonts/*.ttf /usr/share/fonts/
fc-cache -fv

# 4.4.2 compositor (non-VM only)
if systemd-detect-virt -q; then
  log "VM detected, skipping compositor"
else
  pacman_single "picom"
fi

# 4.4.3 display configuration
ln -sf /usr/bin/arandr /usr/local/bin/displays

# 4.4.4 NVIDIA drivers
if [[ $install_nvidia == "y" ]]; then
  pacman_batch "nvidia" "nvidia-utils" "nvidia-settings"
fi

# 4.5 dotfiles
sudo -u "$username" git clone https://github.com/schnyle/dotfiles.git /home/$username/.dotfiles
sudo -u "$username" bash /home/$username/.dotfiles/install.sh

# 4.6 symlinks
ln -sf /usr/bin/pavucontrol /usr/local/bin/audio

# 4.7 third-party software

log "installing third-party software"

# 4.7.1 minesweeper
log "installing minesweeper"
mkdir -p /opt/minesweeper
if curl -fL https://github.com/schnyle/minesweeper/releases/latest/download/minesweeper -o /opt/minesweeper/minesweeper; then
  chmod +x /opt/minesweeper/minesweeper
  ln -sf /opt/minesweeper/minesweeper /usr/local/bin/minesweeper
else
  log "failed to download minesweeper"
  rm -rf /opt/minesweeper
fi
