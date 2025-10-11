# Arch Install

Installation script for creating a new Arch Linux system. Follows the [Installation Guide](https://wiki.archlinux.org/title/Installation_guide). Step 1. Pre-installation is expected to already be completed when this script is run.

To run this script, complete the pre-installation steps and `arch-chroot /mnt`, then run:

```bash
curl -fsSL https://raw.githubusercontent.com/schnyle/arch-install/main/install.sh -o test.sh
```

## 1. Pre-installation

Complete this step manually

## 2. Installation

### 2.1 Select the mirrors

After connecting to the internet, _reflector_ updates the mirror list by choosing 20 most recently synchronized HTTPS mirrors and sorting them by download rate. These mirror servers are defined in `/etc/pacman.d/mirrorlist`

### 2.2 Install essential packages

Perform a basic install of essential packages:

```bash
pacstrap -K /mnt base linux linux-firmware
```

// vim nano

## 3. Configure the system

### 3.1 Fstab

Generate an fstab file, defined by UUID:

```bash
genfstab -U /mnt >> /mnt/etc/fstab
```

### 3.2 Chroot

Change root into the new system:

```bash
arch-chroot /mnt
```

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
