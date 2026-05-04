#!/bin/bash
set -ex

# Using direct-io, this need to be the same as the backing fs sector size
# 4K works for most fs and disks
IMG_SEC_SIZE=${IMG_SEC_SIZE:-4096}
IMG_NEW_POOL_NAME=${IMG_NEW_POOL_NAME:-"img-$(uuidgen)"}
# Subsystem, namespaces and allowed_hosts are managed by remote side
# Only ports are managed here
NVME_OF_PORT=${NVME_OF_PORT:-1}
NVME_OF_BIND_IP=${NVME_OF_BIND_IP:-0.0.0.0}
NVME_OF_BIND_PORT=${NVME_OF_BIND_PORT:-4420}

cfg=/sys/kernel/config/nvmet
port=$cfg/ports/$NVME_OF_PORT

run_in_host() {
    # Sourcing /etc/profile to handle strange environments like nixos
    nsenter -t 1 --mount -- /bin/sh -c "source /etc/profile && $*"
}

run_in_host modprobe loop
run_in_host modprobe nvmet
run_in_host modprobe nvmet_tcp
run_in_host modprobe zfs

setup_lb() {
    lodev=$(losetup -f -b $IMG_SEC_SIZE --direct-io=on --show $IMG_FILE)
}


init() {
    setup_lb
    pool_name=$IMG_NEW_POOL_NAME
    zpool create $pool_name $lodev
    echo "Created zpool with name $pool_name"
    zfs create $pool_name/root
}

import() {
    setup_lb
    pool_info=$(zpool import -d "$lodev")

    if [[ $? -ne 0 ]] || [[ -z "$pool_info" ]]; then
        echo "Error: No valid ZFS pool found"
        exit 1
    fi

    pool_name=$(echo "$pool_info" | grep "pool:" | awk '{print $2}')
    pool_id=$(echo "$pool_info" | grep "id:" | awk '{print $2}')

    echo "ZPool name $pool_name, id $pool_id"

    zpool import -f -d $lodev $pool_id
}

setup_nvmet() {
    nvmetcli restore /etc/nvmet/config.json || :
    mkdir -p $port
    echo $NVME_OF_BIND_IP > $port/addr_traddr
    echo tcp > $port/addr_trtype
    echo $NVME_OF_BIND_PORT > $port/addr_trsvcid
    echo ipv4 > $port/addr_adrfam
    nvmetcli save /etc/nvmet/config.json
}

cleanup_nvmet() {
    for port_link in $port/subsystems/*; do
        rm -f $port_link
    done
    rmdir $port || :
}



cleanup() {
    nvmetcli save /etc/nvmet/config.json
    cleanup_nvmet
    [[ -z $USE_EXISTING_POOL ]] && zpool export $pool_name || :
    [[ -n $lodev ]] && losetup -d $lodev
}

trap cleanup EXIT

if [[ -z $USE_EXISTING_POOL ]]; then
    # Use image file backed zpool
    if [[ $1 == init ]]; then
        shift
        init
    else
        import
    fi
fi

setup_nvmet

# Setup host keys according to env
if [[ -n $SSH_HOST_KEY_DIR ]]; then
    cp -rvf $SSH_HOST_KEY_DIR/. /etc/ssh/
    chmod 600 /etc/ssh/ssh_host_*_key
    chmod 644 /etc/ssh/ssh_host_*_key.pub
else
    ssh-keygen -A
fi

/usr/bin/sshd -eD $SSH_SERVER_FLAGS