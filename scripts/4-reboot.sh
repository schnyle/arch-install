#!/bin/bash

SCRIPTS_DIR="$(dirname "$(realpath "$0")")"
source "$SCRIPTS_DIR/helpers/log.sh"

log "running step 4 - reboot"

reboot
