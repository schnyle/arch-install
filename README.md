# Arch Install

Automated Arch Linux installation script that follows the [Arch Installation Guide](https://wiki.archlinux.org/title/Installation_guide).

## Overview

This script automates the standard Arch Linux installation process:

1. **Pre-installation**: Disk partitioning, formatting, and mounting
2. **Installation**: Base system installation with `pacstrap`
3. **Configure the system**: Timezone, locale, hostname, users, bootloader
4. **Reboot**: Into the new system
5. **Post-installation**: User creation, software installation, system configuration

The script can either handle the entire process automatically or detect if you've completed step 1 manually and continue from there.

## Usage

### Option 1: Full Automation (Recommended)

Run the script directly from the Arch live environment. The script will prompt you to select a disk, then automatically partition and format it, install the base system, configure everything, and reboot into your new installation.

### Option 2: Manual Disk Setup

If you prefer to handle disk partitioning manually, complete step 1 from the [Arch Installation Guide](https://wiki.archlinux.org/title/Installation_guide) (partition disk, format, and mount at `/mnt`) first. The script will auto-detect that `/mnt` is mounted and skip disk setup, proceeding directly to system installation and configuration.

### Running the Script

For either option, run this command from the Arch live environment:

```bash
curl -fsSL https://raw.githubusercontent.com/schnyle/arch-install/main/bootstrap.sh | \
  tee bootstrap.sh | \
  sha256sum -c <(curl -fsSL https://raw.githubusercontent.com/schnyle/arch-install/main/bootstrap.sh.sha256) && \
  bash bootstrap.sh
```

## Development

After cloning this repo, setup the pre commit hooks with:

```bash
git config core.hooksPath hooks
```

## Requirements

- UEFI system (BIOS support available but not primary focus)
- Internet connection
- At least 4GB RAM recommended
- 20GB+ disk space
