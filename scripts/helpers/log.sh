#!/bin/bash

# redirect all output to
exec > >(tee -a /var/log/arch-install-verbose.log) 2>&1

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
