if [[ -d /etc/shell-hooks ]]; then
    for hook_script in /etc/shell-hooks/*; do
        [[ -f "$hook_script" ]] && source "$hook_script"
    done
fi