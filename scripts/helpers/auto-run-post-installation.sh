#!/bin/bash

# setup auto-login
mkdir -p /mnt/etc/systemd/system/getty@tty1.service.d
cat >/mnt/etc/systemd/system/getty@tty1.service.d/autologin.conf <<"EOF"
[Service]
ExecStart=
ExecStart=-/sbin/agetty -o '-p -f -- \\u' --noclear --autologin root - $TERM
EOF

# add auto-run to .bash_profile
cat >>/mnt/root/.bash_profile <<"EOF"

# auto-run post-installation script
if [ -f ~/tmp/arch-install/scripts/5-post-installation.sh ]; then
  ~/tmp/arch-install/scripts/5-post-installation.sh

  # cleanup
  rm -rf ~/tmp/arch-install
  rm -f /etc/systemd/system/getty@tty1.service.d/autologin.conf
  rmdir /etc/systemd/system/getty@tty1.service.d 2> /dev/null

  sed -i '/# auto-run post-installation script/,/# end auto-run/d' ~/.bash_profile
fi
# end auto-run
EOF
