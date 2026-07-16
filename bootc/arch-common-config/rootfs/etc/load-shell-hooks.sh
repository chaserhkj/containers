shopt -q nullglob && _nullglob_set=1 || _nullglob_set=0
shopt -s nullglob
if [[ -d /etc/shell-hooks ]]; then
    for hook_script in /etc/shell-hooks/*; do
        [[ -f "$hook_script" ]] && source "$hook_script"
    done
fi
(( ! $_nullglob_set )) && shopt -u nullglob
unset _nullglob_set