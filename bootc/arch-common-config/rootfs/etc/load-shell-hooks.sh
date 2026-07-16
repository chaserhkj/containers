hook_dir=/etc/shell-hooks
if [[ -d "$hook_dir" ]] && [[ -n "$(ls "$hook_dir")" ]]; then
    for hook_script in "$hook_dir"/*; do
        [[ -f "$hook_script" ]] && source "$hook_script"
    done
fi