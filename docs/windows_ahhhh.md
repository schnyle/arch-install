# If Windows decides to be a hooligan and mess with GRUB, try this

# Find your partitions
lsblk

# Mount root partition (replace sdXY with yours)
mount /dev/sdXY /mnt

# Mount EFI partition (usually sda1 or nvme0n1p1)
mount /dev/sdXZ /mnt/boot  # or /mnt/boot/efi depending on your setup

# Mount other partitions if needed (/home, etc.)

# Chroot into your system
arch-chroot /mnt

# Reinstall GRUB
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB

# Regenerate config
grub-mkconfig -o /boot/grub/grub.cfg

# Exit chroot
exit

# Before chrooting, check current entries
efibootmgr -v

# If GRUB entry exists but wrong order:
efibootmgr -o 0001,0000  # put GRUB first (adjust numbers based on output)