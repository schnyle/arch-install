#!/bin/bash

# 4. Reboot

SCRIPTS_DIR="$(dirname "$(realpath "$0")")"
source "$SCRIPTS_DIR/helpers/log.sh"

loginfo "starting 4. reboot"

reboot
