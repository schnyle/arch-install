#!/bin/bash

# create systemd drop-in directory for tty1 getty service
mkdir -p /mnt/etc/systemd/system/getty@tty1.service.d

# modify tty1 getty service to auto-login as root
cat >/mnt/etc/systemd/system/getty@tty1.service.d/autologin.conf <<"EOF"
[Service]
# clear previous ExecStart directives
ExecStart=
# auto-login as root, preserving environment variables
ExecStart=-/sbin/agetty -o '-p -f -- \\u' --noclear --autologin root - $TERM
EOF

# create .bash_profile to auto-run post-installation script on login, cleanup, and reboot
cat >/mnt/root/.bash_profile <<"EOF"
/root/tmp/arch/scripts/5-post-installation.sh && \
rm -rf /root/tmp/arch && \
rm -f /etc/systemd/system/getty@tty1.service.d/autologin.conf && \
rmdir /etc/systemd/system/getty@tty1.service.d 2>/dev/null && \
rm -f /root/.bash_profile && \
reboot
EOF
