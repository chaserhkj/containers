#!/bin/bash
set -euo pipefail

nvmeof_class=${1:?"Must specify nvmeof target class in arg 1"}
PREFIX="/var/lib/k0s/kubelet/plugins/kubernetes.io/csi/org.democratic-csi.nvmeof.$nvmeof_class/"
PRE_TARGET="nvmeof-$nvmeof_class-pre.target"
TARGET="nvmeof-$nvmeof_class.target"

RUNTIME_DIR='/run/systemd/system'

path_to_unit() {
    systemd-escape --path --suffix=mount "$1"
}

write_dropin() {
    local mountpoint="$1"
    local unit_name
    unit_name=$(path_to_unit "$mountpoint")
    local dropin_dir="${RUNTIME_DIR}/${unit_name}.d"

    mkdir -p "$dropin_dir"

    cat > "${dropin_dir}/dependency.conf" <<-EOF
[Unit]
DefaultDependencies=no
Requires=${PRE_TARGET}
After=${PRE_TARGET}
EOF

    local dep_dropin_dir="${RUNTIME_DIR}/${TARGET}.d"

    mkdir -p "$dep_dropin_dir"

    cat > "${dep_dropin_dir}/wants-${unit_name}.conf" <<-EOF
[Unit]
Wants=${unit_name}
EOF

    systemctl daemon-reload
}

echo "k0s-nvmeof-mount-watcher: scanning existing mounts..."
findmnt --output TARGET --raw --noheadings 2>/dev/null \
    | while read -r target; do
        if [[ "$target" == "$PREFIX"* ]]; then
            write_dropin "$target"
        fi
    done

echo "k0s-nvmeof-mount-watcher: listening for new mounts..."
findmnt --poll=mount --output TARGET --raw --noheadings 2>/dev/null \
    | while read -r target; do
        if [[ "$target" == "$PREFIX"* ]]; then
            write_dropin "$target"
        fi
    done
