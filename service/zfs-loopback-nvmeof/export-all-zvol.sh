#!/bin/bash
set -ex
zvol_prefix=${1:?"Required argument: zvol_prefix"}

base=/sys/kernel/config/nvmet

for vol in /dev/zvol/$zvol_prefix*; do
    name=$(basename $vol)
    path=$vol
    nqn_name="nqn.2003-01.org.linux-nvme:$name"
    mkdir -p "$base/subsystems/$nqn_name"
    mkdir -p "$base/subsystems/$nqn_name/namespaces/1"
    read current_path < "$base/subsystems/$nqn_name/namespaces/1/device_path"
    if [[ "$current_path" == "(null)" ]]; then
        echo "$path" > "$base/subsystems/$nqn_name/namespaces/1/device_path"
    fi
    echo 1 > "$base/subsystems/$nqn_name/attr_allow_any_host"
    if [[ ! -e "$base/ports/1/subsystems/$nqn_name" ]]; then
        ln -sf "../../../../nvmet/subsystems/$nqn_name" -t "$base/ports/1/subsystems"
    fi
    echo 1 > "$base/subsystems/$nqn_name/namespaces/1/enable"
done

nvmetcli save /etc/nvmet/config.json || :