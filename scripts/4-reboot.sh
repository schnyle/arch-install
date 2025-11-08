#!/bin/bash

# 4. Reboot

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
source "$SCRIPT_DIR/../bootstrap.sh"

source "$REPO_DIR/scripts/log.sh"

loginfo "starting 4. reboot"

reboot
