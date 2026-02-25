#!/bin/bash
set -ex

# Using direct-io, this need to be the same as the backing fs sector size
# 4K works for most fs and disks
IMG_SEC_SIZE=${IMG_SEC_SIZE:-4096}
NVME_OF_SUBSYS=${NVME_OF_SUBSYS:-loopback-nvmeof}
NVME_OF_NS=${NVME_OF_NS:-1}
NVME_OF_PORT=${NVME_OF_PORT:-1}
NVME_OF_BIND_IP=${NVME_OF_BIND_IP:-0.0.0.0}
NVME_OF_BIND_PORT=${NVME_OF_BIND_PORT:-4420}
NVME_OF_CLIENT_NQN=${NVME_OF_CLIENT_NQN:-"nqn.2014-08.org.nvmexpress:uuid:0dd0449d-53c0-4ce4-882e-07f2006fa665"}

cfg=/sys/kernel/config/nvmet
sys=$cfg/subsystems/$NVME_OF_SUBSYS
ns=$sys/namespaces/$NVME_OF_NS
port=$cfg/ports/$NVME_OF_PORT
host=$cfg/hosts/$NVME_OF_CLIENT_NQN

run_in_host() {
    # Sourcing /etc/profile to handle strange environments like nixos
    nsenter -t 1 --mount -- /bin/sh -c "source /etc/profile && $*"
}

run_in_host modprobe loop
run_in_host modprobe nvmet
run_in_host modprobe nvmet_tcp

setup_lb() {
    lodev=$(losetup -f -b $IMG_SEC_SIZE --direct-io=on --show $IMG_FILE)
}


setup_nvmet() {
    mkdir -p $sys
    mkdir -p $ns
    echo $lodev > $ns/device_path
    echo 1 > $ns/enable
    mkdir -p $port
    echo $NVME_OF_BIND_IP > $port/addr_traddr
    echo tcp > $port/addr_trtype
    echo $NVME_OF_BIND_PORT > $port/addr_trsvcid
    echo ipv4 > $port/addr_adrfam
    ln -s $sys $port/subsystems
    mkdir -p $host
    ln -s $host $sys/allowed_hosts
}

cleanup_nvmet() {
    echo 0 > $ns/enable
    rm -f $sys/allowed_hosts/$NVME_OF_CLIENT_NQN
    rm -f $port/subsystems/$NVME_OF_SUBSYS
    rmdir $host || :
    rmdir $port || :
    rmdir $ns || :
    rmdir $sys || :
}

cleanup() {
    cleanup_nvmet
    [[ -n $lodev ]] && losetup -d $lodev
}

trap cleanup EXIT


setup_lb
setup_nvmet

sleep infinity


