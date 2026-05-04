#!/bin/bash
set -e

zvol_prefix=${1:?"Required argument: zvol_prefix"}
shift

base=/sys/kernel/config/nvmet

declare -A used_volumes
while read vol; do
    [[ -n $vol ]] && used_volumes[$vol]=1
done

candidates=()
for path in /dev/zvol/$zvol_prefix*; do
    vol=$(basename $path)
    if [[ "${used_volumes[$vol]}" == "1" ]]; then
        echo "$vol is in use"
    else
        echo "mark $vol for deletion"
        candidates+=($vol)
    fi
done

if [[ $1 == -f ]]; then
    for vol in "${candidates[@]}"; do
        echo "deleting $vol"
        nqn_name="nqn.2003-01.org.linux-nvme:$vol"
        if [[ -d "$base/subsystems/$nqn_name" ]]; then
            echo "Removing from NVME target"
            rm -f "$base/ports/1/subsystems/$nqn_name"
            rmdir "$base/subsystems/$nqn_name/namespaces/1"
            rmdir "$base/subsystems/$nqn_name"
            nvmetcli save /etc/nvmet/config.json || :
        fi
        echo "Removing from ZFS"
        zfs destroy -r "${zvol_prefix}$vol" || echo "WARNING: Volume $vol might still be indirectly used!"
    done
fi