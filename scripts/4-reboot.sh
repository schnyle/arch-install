#!/bin/bash

# 4. Reboot

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
source "$SCRIPT_DIR/../bootstrap.sh"

loginfo "starting 4. reboot"

reboot
