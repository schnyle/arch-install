# Manual Installation Steps

> **Complete these steps before running the automated installation script.**

## Prerequisites

- Boot from Arch Linux installation media
- Verify UEFI mode: `ls /sys/firmware/efi` (directory should exist)
- Identify your disk: `lsblk` (usually `/dev/sda` or `/dev/nvme0n1`)

## 1. Partition the disk with fdisk

```bash
fdisk /dev/sda
```

**Inside fdisk:**

- Press `g` to create a new GPT partition table
- Press `n` to create partition 1 (EFI)
  - Partition number: `1` (default)
  - First sector: (default)
  - Last sector: `+512M`
- Press `t` to change type
  - Partition type: `1` (EFI System)
- Press `n` to create partition 2 (Swap)
  - Partition number: `2` (default)
  - First sector: (default)
  - Last sector: `+4G` (adjust to your RAM size)
- Press `t` to change type
  - Partition number: `2`
  - Partition type: `19` (Linux swap)
- Press `n` to create partition 3 (Root)
  - Partition number: `3` (default)
  - First sector: (default)
  - Last sector: (default, use remaining space)
- Press `p` to review the partition table
- Press `w` to write changes and exit

## 2. Format the partitions

```bash
mkfs.fat -F32 /dev/sda1  # Format EFI partition
mkswap /dev/sda2         # Format swap partition
swapon /dev/sda2         # Enable swap
mkfs.ext4 /dev/sda3      # Format root partition
```

## 3. Mount the file systems

```bash
mount /dev/sda3 /mnt               # Mount root partition
mount --mkdir /dev/sda1 /mnt/boot  # Mount EFI partition
```

## 4. Install the base system

```bash
pacstrap /mnt base linux linux-firmware
```

Optional additional packages:

```bash
pacstrap /mnt base linux linux-firmware nano vim networkmanager
```

## 5. Generate fstab

```bash
genfstab -U /mnt >> /mnt/etc/fstab
```

## 6. Chroot into the new system

```bash
arch-chroot /mnt
```

## Dual-Boot Notes

**For dual-boot installations:**

- Do NOT create a new partition table with `g` in fdisk
- Reuse the existing EFI partition (do not format it)
- Only create new partitions for swap and root in free space
- Install `os-prober` with GRUB to detect other operating systems

## Troubleshooting

**If you get "EFI variables not supported":**

- Check if you're in UEFI mode: `ls /sys/firmware/efi`
- For VMs, enable UEFI/EFI in VM settings before installation
- For BIOS mode, use: `grub-install --target=i386-pc /dev/sda`

**If grub-install fails on VM:**
Try adding `--no-nvram` flag:

```bash
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --no-nvram
```
