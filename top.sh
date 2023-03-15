#!/bin/bash

host=$1
resource=$2

if [[ -z "$1"  || -z "$2" ]]; then
  echo "Usage: $0 <hostname cpu (or mem)>"
  exit 1
fi

case "$2" in
  "cpu")
    echo "CPU usage:"
    ssh -q $host 'echo "$(ps -eo pcpu,pid,user,command --sort -pcpu | head)"'
    ;;
  "mem")
    echo "Memory usage:"
    ssh -q $host "ps -eo size,pid,user,\command --sort -size" | awk '{ byte=$1/1024 ; printf("%1f Mb ",byte) } {print $0}' | head
    ;;
esac
