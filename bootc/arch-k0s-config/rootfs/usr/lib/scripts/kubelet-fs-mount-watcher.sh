#!/bin/bash
set -euo pipefail

PREFIX="/var/lib/k0s/kubelet/"
PRE_TARGET="kubelet-fs-pre.target"
TARGET="kubelet-fs.target"

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
Before=umount.target ${TARGET}
Conflicts=umount.target
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

echo "kubelet-fs-mount-watcher: scanning existing mounts..."
findmnt --output TARGET --raw --noheadings 2>/dev/null \
    | while read -r target; do
        if [[ "$target" == "$PREFIX"* ]]; then
            write_dropin "$target"
        fi
    done

echo "kubelet-fs-mount-watcher: listening for new mounts..."
findmnt --poll=mount --output TARGET --raw --noheadings 2>/dev/null \
    | while read -r target; do
        if [[ "$target" == "$PREFIX"* ]]; then
            write_dropin "$target"
        fi
    done
