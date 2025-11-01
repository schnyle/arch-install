#!/bin/bash

SCRIPTS_DIR="$(dirname "$(realpath "$0")")"
source "$SCRIPTS_DIR/helpers/log.sh"
source "$SCRIPTS_DIR/helpers/pacman-install.sh"

# ~~~ 4. custom installation ~~~

pacman -Sy

# enable multilib repository for 32-bit packages
sed -i '/^#\[multilib\]/,/^#Include/ {s/^#//; }' /etc/pacman.conf

# start networkmanager
systemctl start NetworkManager

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
    log "Error: Failed to create user '$username'. User may already exist or invalid characters used."
  fi
done

while true; do
  if passwd "$username"; then
    break
  fi
done

# enable wheel group sudo access for new user
sed -i "s/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/" /etc/sudoers

# 4.1.2 oh-my-zsh

pacmansync git zsh
sudo -u "$username" bash -c "curl -L https://install.ohmyz.sh | sh"
sudo -u "$username" chsh -s /usr/bin/zsh

# 4.1.3 enable pulse audio
mkdir -p /home/$username/.config/systemd/user/default.target.wants
ln -sf /usr/lib/systemd/user/pulseaudio.service /home/$username/.config/systemd/user/default.target.wants/
chown -R $username:$username /home/$username/.config

# 4.1.4 install Arch User Repository helper
log "installing yay"
pacmansync base-devel
if ! git clone https://aur.archlinux.org/yay.git /opt/yay; then
  log "error: failed to clone yay repository"
  exit 1
fi

chown -R $username:$username /opt/yay
if ! sudo -u "$username" makepkg -si -D /opt/yay --noconfirm; then
  log "error: failed to build yay"
  exit 1
fi

# 4.1.5 collect user preferences
install_package_prompt() {
  echo "Install $@? (y/n)"
  read -r user_input
  if [[ $user_input == "y" ]]; then
    log "user chose to install $@"
    return 0
  else
    log "user chose to not install $@"
    return 1
  fi
}

echo "Install all optional software? (y/n)"
read -r install_all

install_minesweeper="y"
install_nvidia="y"
install_steam="y"
install_vscode="y"

if [[ $install_all == "y" ]]; then
  log "user chose to install all optional software"
else
  log "user chose to not install all optional software"

  if ! install_package_prompt "Minesweeper"; then
    install_minesweeper="n"
  fi

  if ! install_package_prompt "NVIDIA drivers"; then
    install_nvidia="n"
  fi

  if ! install_package_prompt "Steam"; then
    install_steam="n"
  fi

  if ! install_package_prompt "VS Code"; then
    install_vscode="n"
  fi
fi

# 4.2 first-party software

ARCH_INSTALL_DIR="$(dirname "$SCRIPTS_DIR")"
PACMAN_PACKAGES_FILE_PATH="$ARCH_INSTALL_DIR/pacman-packages"

packages=()
while IFS= read -r line; do
  line="${line%%#*}"
  line=$(echo "$line" | xargs)

  [[ -z "$line" ]] && continue

  packages+=("$line")
done <"$PACMAN_PACKAGES_FILE_PATH"

log "Installing ${#packages[@]} pacman packages"
pacmansync "${packages[@]}"

# 4.3 graphics/ui

# 4.3.1 fonts
mkdir /usr/share/fonts
cp /root/tmp/arch-install/fonts/*.ttf /usr/share/fonts/
fc-cache -fv

# 4.3.2 compositor (non-VM only)
if systemd-detect-virt -q; then
  log "VM detected, skipping compositor"
else
  pacmansync picom
fi

# 4.3.3 display configuration
ln -sf /usr/bin/arandr /usr/local/bin/displays

# 4.3.4 NVIDIA drivers
if [[ $install_nvidia == "y" ]]; then
  pacmansync nvidia nvidia-utils nvidia-settings
fi

# 4.4 dotfiles
if sudo -u "$username" git clone https://github.com/schnyle/dotfiles.git /home/$username/.dotfiles; then
  sudo -u "$username" bash /home/$username/.dotfiles/install.sh
else
  log "warning: failed to clone dotfiles repository"
fi

# 4.5 symlinks
ln -sf /usr/bin/pavucontrol /usr/local/bin/audio

# 4.6 third-party software

log "installing third-party software"

# 4.6.1 minesweeper
if [[ $install_minesweeper == "y" ]]; then
  log "installing minesweeper"
  mkdir -p /opt/minesweeper
  if curl -fL https://github.com/schnyle/minesweeper/releases/latest/download/minesweeper -o /opt/minesweeper/minesweeper; then
    chmod +x /opt/minesweeper/minesweeper
    ln -sf /opt/minesweeper/minesweeper /usr/local/bin/minesweeper
  else
    log "failed to download minesweeper"
    rm -rf /opt/minesweeper
  fi
fi

# 4.6.2 steam
if [[ $install_steam == "y" ]]; then
  log "installing Steam"
  log "WARNING: install lib32-nvidia-utils - assumes NVIDIA GPU"
  pacmansync steam lib32-nvidia-utils
fi

# 4.6.3 VS Code
if [[ $install_vscode == "y" ]]; then
  log "installing VS Code"
  sudo -u "$username" yay -S --noconfirm visual-studio-code-bin

  log "installing VS Code extensions"
  sudo -u "$username" code --install-extension ms-vscode.cmake-tools
  sudo -u "$username" code --install-extension ms-vscode.cpptools
  sudo -u "$username" code --install-extension vscode-icons-team.vscode-icons
  sudo -u "$username" code --install-extension tomoki1207.pdf
  sudo -u "$username" code --install-extension mechatroner.rainbow-csv
fi
