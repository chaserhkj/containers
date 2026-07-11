
_save_current_env() {
    (( ${_DO_NOT_SAVE_ENV:0} )) && return
    [[ ! -d "$XDG_RUNTIME_DIR" ]] && return
    if [[ -n "$WAYLAND_DISPLAY" ]] || [[ -n "$DISPLAY" ]]; then
        env -0 > "$XDG_RUNTIME_DIR/gui.env"
    fi
    env -0 > "$XDG_RUNTIME_DIR/shell.env"
}

precmd_functions+=(_save_current_env)