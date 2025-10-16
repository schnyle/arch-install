# Arch Install

Automated Arch Linux installation script.

## Usage

Complete steps 1., 2., 3.1, and 3.2 from the [Arch Installation Guide](https://wiki.archlinux.org/title/Installation_guide), then run:

```bash
curl -fsSL https://raw.githubusercontent.com/schnyle/arch-install/main/install.sh | \
  tee install.sh | \
  sha256sum -c <(curl -fsSL https://raw.githubusercontent.com/schnyle/arch-install/main/install.sh.sha256) && \
  bash install.sh
```

## Options

- `-v, --verbose` - Show verbose output

## Setup

After cloning this repo, setup the pre commit hooks with:

```bash
git config core.hooksPath hooks
```
