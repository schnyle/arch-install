# Automated Installation Steps

> **Prerequisites:** Complete steps 1-3.2 manually following [manual-steps.md](manual-steps.md) before running the installation script.

This document outlines what the automated installation script performs, starting from step 3.3 after you've chrooted into the new system.

## 3. Configure the system (continued)

### 3.3 Time

Set the time zone (default Denver):

```bash
ln -sf /usr/share/zoneinfo/America/Denver /etc/localtime
```

Run hwclock to generate `/etc/adjtime`:

```bash
hwclock --systohc
```

### 3.4 Localization

Generate locales for correct region and language specific formatting, edit `/etc/locale.gen` and uncomment the desired UTF-8 locales (default `en_US.UTF-8 UTF-8`).

Then generate the locales by running:

```bash
locale-gen
```

Create the `locale.conf` file, and set the LANG variable accordingly

```
LANG=en_US.UTF-8
```

### 3.5 Network Configuration

Create the hostname file `/etc/hostname` with the hostname (default `archlinux`)

// do more??? install a networkd and set it to enable?

### 3.6 Initramfs

Creating a new _initramfs_ is usually not required, because mkinitcpio was run on installation of the kernel package with _pacstrap_.

### 3.7 Root password

Set a secure password for the root user:

```bash
passwd
```

### 3.8 Boot loader

Install the GRUB bootloader. Use the `os-prober` package to help GRUB find existing OS installations:

```bash
pacman -S grub efibootmgr os-prober
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
```

for VM:

```bash
grub-install --target=i386-pc /dev/vda
grub-mkconfig -o /boot/grub/grub.cfg
```

## 4. Custom installation

### 4.1 Create a user
