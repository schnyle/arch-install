#!/bin/bash

# 3. Configure the system

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source "$SCRIPT_DIR/../bootstrap.sh"

source "$REPO_DIR/scripts/pacman-install.sh"

loginfo "starting 3. configure the system"

# 3.1 Fstab
loginfo "generating 'fstab' file"
if ! genfstab -U /mnt >>/mnt/etc/fstab; then
  logerr "error: failed to generate fstab"
  exit 1
fi

if [[ ! -s /mnt/etc/fstab ]]; then
  logerr "error: fstab is empty"
  exit 1
fi

# 3.2 Chroot
# will run chroot steps from live environment

# 3.3 time
loginfo "setting the timezone to America/Denver"
arch-chroot /mnt ln -sf /usr/share/zoneinfo/America/Denver /etc/localtime
arch-chroot /mnt hwclock --systohc

# 3.4 localization
loginfo "setting locale to en_US.UTF-8"
arch-chroot /mnt sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
arch-chroot /mnt locale-gen
arch-chroot /mnt touch /etc/locale.conf
echo "LANG=en_US.UTF-8" >/mnt/etc/locale.conf

# 3.5 network configuration
loginfo "creating hostname file"
while true; do
  echo
  echo "System hostname:"
  read -r hostname
  if echo "$hostname" >/mnt/etc/hostname; then
    break
  fi
done

loginfo "user set hostname to '$hostname'"

# 3.6 initramfs
# usually not required

# 3.7 set root password
loginfo "Setting password for root"
while true; do
  if arch-chroot /mnt bash -c "passwd"; then
    break
  fi
done

# 3.8 boot loader
chroot_with_env() {
  arch-chroot /mnt bash -c "
    source $REPO_DIR/bootstrap.sh
    source $REPO_DIR/scripts/pacman-install.sh
    $*
  "
}

loginfo "install grub bootloader"
chroot_with_env pacmansync grub efibootmgr os-prober
arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
