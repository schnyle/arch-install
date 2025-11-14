#!/bin/bash

# 3. Configure the system

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source "$SCRIPT_DIR/../bootstrap.sh"

source "$REPO_DIR/scripts/pacman-install.sh"

chroot_with_env() {
  arch-chroot /mnt bash -c "
    source $REPO_DIR/bootstrap.sh
    source $REPO_DIR/scripts/pacman-install.sh
    $*
  "
}

install_boot_loader() {
  if ! chroot_with_env pacmansync grub efibootmgr os-prober; then
    logerr "failed to install essential packages for boot loader"
    return 1
  fi

  if ! arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB; then
    logerr "failed to install grub"
    return 1
  fi

  if ! arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg; then
    logerr "failed to configure grub"
    return 1
  fi

}

loginfo "3.1 Fstab"
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

loginfo "3.3 Time"
arch-chroot /mnt ln -sf /usr/share/zoneinfo/America/Denver /etc/localtime || logwarn "failed to set the time zone"
arch-chroot /mnt hwclock --systohc || logwarn "failed to set the hardware clock"

loginfo "3.4 Localization"
arch-chroot /mnt sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen || logwarn "failed to edit /etc/locale.gen"
arch-chroot /mnt locale-gen || logwarn "failed to generate locales"
arch-chroot /mnt touch /etc/locale.conf || logwarn "failed to create /etc/locale.conf"
echo "LANG=en_US.UTF-8" >/mnt/etc/locale.conf || logwarn "failed to set the language"

loginfo "3.5 Network configuration"
while true; do
  echo
  echo "System hostname:"
  read -r user_hostname
  if echo "$user_hostname" >/mnt/etc/hostname; then
    loginfo "user set hostname to '$user_hostname'"
    break
  fi
done

etc_hostname=$(cat /mnt/etc/hostname)
[[ "$etc_hostname" == "$user_hostname" ]] || logwarn "error setting system hostname: expected $user_hostname, got $etc_hostname"

# 3.6 initramfs
# usually not required

loginfo "3.7 Root password"
while true; do
  if arch-chroot /mnt bash -c "passwd"; then
    break
  fi
done

loginfo "3.8 Boot loader"
if ! install_boot_loader; then
  logerr "failed to install boot loader"
  exit 1
fi
