#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <location_name>"
    exit 1
fi

LOC=$1
# 12450
hosts_list=$(ssh $LOC-controller curl -s localhost:9192/hosts | jq '.hosts | keys | .[]' | cut -d\" -f 2 | grep "$LOC-controller-*")
port_list=$(echo {12450..12462..1})
for h in $hosts_list; do
    for p in ${port_list[@]}; do
        echo "$h:$p"
        ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=quiet $h "ss -nlpa | grep $p"
    done
done
