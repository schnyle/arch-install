#!/bin/bash

# 5. Post-installation

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
source "$SCRIPT_DIR/../bootstrap.sh"

source "$REPO_DIR/scripts/pacman-install.sh"

loginfo "starting 5. post-installation"

if ! pacman-key --init; then
  logerr "failed to initialize pacman keyring"
  exit 1
fi

if ! pacman-key --populate archlinux; then
  logerr "failed to populate archlinux keyring"
  exit 1
fi
#
# enable multilib repository for 32-bit packages
sed -i '/^#\[multilib\]/,/^#Include/ {s/^#//; }' /etc/pacman.conf

loginfo "waiting for network connectivity"
timeout=60
while ! ping -c 1 8.8.8.8 >/dev/null 2>&1; do
  if [[ timeout -le 0 ]]; then
    logerr "failed to establish network connection"
    exit 1
  fi
  sleep 1
  ((timeout--))
done

if ! pacman -Sy --noconfirm; then
  logerr "failed to sync package database"
fi

# 5.1 user setup

# 5.1.1 create new user
loginfo "Creating new wheel user"
while true; do
  echo
  echo "New username:"
  read -r username
  if [[ -z "$username" ]]; then
    logerr "username cannot be empty"
    continue
  fi

  if useradd -m -G wheel "$username"; then
    break
  else
    logerr "failed to create user '$username'. user may already exist or invalid characters used."
  fi
done

while true; do
  if passwd "$username"; then
    break
  fi
done

sed -i "s/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/" /etc/sudoers

loginfo "configuring temporary passwordless sudo for $username"
echo "$username ALL=(ALL) NOPASSWD: ALL" >/etc/sudoers.d/temp_install
chmod 440 /etc/sudoers.d/temp_install

# 5.1.2 oh-my-zsh
loginfo "installing oh-my-zsh"
pacmansync git zsh
sudo -u "$username" bash -c "curl -L https://install.ohmyz.sh | sh"
chsh -s /usr/bin/zsh "$username"

# 5.1.3 enable pulse audio
loginfo "enabling pulse audio user service"
mkdir -p /home/$username/.config/systemd/user/default.target.wants
ln -sf /usr/lib/systemd/user/pulseaudio.service /home/$username/.config/systemd/user/default.target.wants/
chown -R $username:$username /home/$username/.config

# 5.1.4 install Arch User Repository helper
loginfo "installing yay"
pacmansync base-devel
if ! git clone https://aur.archlinux.org/yay.git /opt/yay; then
  logerr "failed to clone yay repository"
  exit 1
fi

chown -R $username:$username /opt/yay
if ! sudo -u "$username" makepkg -si -D /opt/yay --noconfirm; then
  logerr "failed to build yay"
  exit 1
fi

# 5.1.5 collect user preferences
loginfo "collecting user preferences"
install_package_prompt() {
  echo
  echo "Install $@? (y/n)"
  read -r user_input
  if [[ $user_input == "y" ]]; then
    loginfo "user chose to install $@"
    return 0
  else
    loginfo "user chose to not install $@"
    return 1
  fi
}

echo
echo "Install all optional software? (y/n)"
read -r install_all

install_minesweeper="y"
install_nvidia="y"
install_steam="y"
install_vscode="y"

if [[ $install_all == "y" ]]; then
  loginfo "user chose to install all optional software"
else
  loginfo "user chose to not install all optional software"

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

# 5.2 first-party software
loginfo "Installing first-party software"

packages=()
while IFS= read -r line; do
  line="${line%%#*}"
  line=$(echo "$line" | xargs)

  [[ -z "$line" ]] && continue

  packages+=("$line")
done <"$REPO_DIR/pacman-packages"

loginfo "installing $# pacman packages"
pacmansync "${packages[@]}"

# 5.3 graphics/ui
loginfo "install and configure graphics/ui software"

# 5.3.1 fonts
loginfo "copying fonts to system"
mkdir /usr/share/fonts
cp /root/tmp/arch-install/fonts/*.ttf /usr/share/fonts/
fc-cache -fv

# 5.3.2 compositor (non-VM only)
loginfo "installating compositor"
if systemd-detect-virt -q; then
  loginfo "VM detected, skipping compositor"
else
  pacmansync picom
fi

# 5.3.3 display configuration
loginfo "making 'displays' symlink for display configuration software"
ln -sf /usr/bin/arandr /usr/local/bin/displays

# 5.3.4 NVIDIA drivers
if [[ $install_nvidia == "y" ]]; then
  loginfo "installing nvidia drivers"
  pacmansync nvidia nvidia-utils nvidia-settings
fi

# 5.4 dotfiles
loginfo "clone dotfiles repository"
if sudo -u "$username" git clone https://github.com/schnyle/dotfiles.git /home/$username/.dotfiles; then
  sudo -u "$username" bash /home/$username/.dotfiles/install.sh
else
  logwarn "failed to clone dotfiles repository"
fi

# 5.5 symlinks
loginfo "making 'audio' symlink for audio configuration software"
ln -sf /usr/bin/pavucontrol /usr/local/bin/audio

# 5.6 third-party software
loginfo "installing third-party software"

# 5.6.1 minesweeper
if [[ $install_minesweeper == "y" ]]; then
  loginfo "installing minesweeper"
  mkdir -p /opt/minesweeper
  if curl -fL https://github.com/schnyle/minesweeper/releases/latest/download/minesweeper -o /opt/minesweeper/minesweeper; then
    chmod +x /opt/minesweeper/minesweeper
    ln -sf /opt/minesweeper/minesweeper /usr/local/bin/minesweeper
  else
    logwarn "failed to download minesweeper"
    rm -rf /opt/minesweeper
  fi
fi

# 5.6.2 steam
if [[ $install_steam == "y" ]]; then
  loginfo "installing Steam"
  logwarn "installing lib32-nvidia-utils for Steam - assumes NVIDIA GPU"
  pacmansync steam lib32-nvidia-utils
fi

# 5.6.3 VS Code
if [[ $install_vscode == "y" ]]; then
  loginfo "installing VS Code"
  sudo -u "$username" yay -S --noconfirm visual-studio-code-bin

  loginfo "installing VS Code extensions"
  sudo -u "$username" code --install-extension ms-vscode.cmake-tools
  sudo -u "$username" code --install-extension ms-vscode.cpptools
  sudo -u "$username" code --install-extension vscode-icons-team.vscode-icons
  sudo -u "$username" code --install-extension tomoki1207.pdf
  sudo -u "$username" code --install-extension mechatroner.rainbow-csv
fi

# 5.7 cleanup
loginfo "cleaning up post-installation"

rm /etc/sudoers.d/temp_install

reboot
