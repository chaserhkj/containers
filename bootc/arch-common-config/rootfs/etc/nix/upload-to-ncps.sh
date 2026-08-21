#!/bin/bash

[[ -z "${OUT_PATHS}" ]] && exit 0
copy_cmd=(
    nix copy --to
    "https://$(cat /etc/nix/ncps.cred.txt)@ncps.0.zt/upload"
)

can_use_systemd_run() {
    (( ${UPLOAD_TO_NCPS_NO_SYSTEMD:-0} )) && return 1
    command -v systemctl &>/dev/null || return 1
    command -v systemd-escape &>/dev/null || return 1
    command -v systemd-run &>/dev/null || return 1
    systemctl --user is-system-running &>/dev/null || return 1
    return 0
}

copy_for_path() {
    OUT_PATH="$1"
    if can_use_systemd_run; then
        unit_name="nix-copy-for-$(systemd-escape -p "$OUT_PATH").service"
        systemd-run --user --unit="$unit_name" -- "${copy_cmd[@]}" "$OUT_PATH" || :
    else
        log_file="$(realpath -sm "/tmp/nix-copy-logs/$OUT_PATH.log")"
        echo "Dispatching nix copy, writing logs to $log_file"
        mkdir -p "$(dirname $log_file)" && ( setsid "${copy_cmd[@]}" "$OUT_PATH" &>"$log_file" || : ) &
    fi
}

for path in $OUT_PATHS; do
    copy_for_path $path
done