#!/bin/bash

# 3. Configure the system (b)

SCRIPTS_DIR="$(dirname "$(realpath "$0")")"
source "$SCRIPTS_DIR/helpers/log.sh"
source "$SCRIPTS_DIR/helpers/pacman-install.sh"

pacmansync sudo

# 3.3 time
loginfo "setting the timezone to America/Denver"
ln -sf /usr/share/zoneinfo/America/Denver /etc/localtime
hwclock --systohc

# 3.4 localization
loginfo "setting locale to en_US.UTF-8"
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
touch /etc/locale.conf
echo "LANG=en_US.UTF-8" >/etc/locale.conf

# 3.5 network configuration
loginfo "creating hostname file"
while true; do
  prompt "System hostname:"
  read -r hostname
  if echo "$hostname" >/etc/hostname; then
    break
  fi
done

loginfo "user set hostname to '$hostname'"

# 3.6 initramfs
# usually not required

# 3.7 set root password
loginfo "Setting password for root"
while true; do
  if passwd; then
    break
  fi
done

# 3.8 boot loader
loginfo "install grub bootloader"
pacmansync grub efibootmgr os-prober
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
