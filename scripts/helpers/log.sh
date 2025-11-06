#!/bin/bash

# redirect all output to verbose log
if [[ -z "$LOGS_REDIRECTED" ]]; then
  exec > >(tee -a /var/log/arch-install-verbose.log) 2>&1
  export LOGS_REDIRECTED=1
fi

log() {
  msg="$(date '+%Y-%m-%d %H:%M:%S') $*"
  echo "$msg"                             # verbose logfile
  echo "$msg" >>/var/log/arch-install.log # application logfile
}

loginfo() {
  log "[INFO] $*"
}

logwarn() {
  log "[WARNING] $*"
}

logerr() {
  log "[ERROR] $*"
}
