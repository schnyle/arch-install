#!/bin/bash

# Initialize logging (only once per process)
if [[ -z "$LOGGING_INITIALIZED" ]]; then
  export LOGGING_INITIALIZED=1

  # Setup file descriptors
  exec 3>&1                         # save stdout
  exec 4>>/var/log/arch-install.log # direct log file access

  # Setup indented output for system commands
  indent_and_log() {
    while IFS= read -r line; do
      output="    $line"
      echo "$output" >&3
      echo "$output" >&4
    done
  }

  exec > >(indent_and_log) 2>&1
fi

log() {
  echo "$*" >&3 # send to terminal (unindented)
  echo "$*" >&4 # send to logfile (unindented)
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

prompt() {
  echo >&3
  echo "$*" >&3
}
