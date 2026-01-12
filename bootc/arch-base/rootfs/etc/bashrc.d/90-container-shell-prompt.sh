
_prompt_container() {
    if [[ -f /run/.containerenv ]]; then
        local prefix="ctr/"
        [[ -n $container ]] && prefix+="$container/"
        [[ -f /run/.toolboxenv ]] && prefix+="tlbx/"
        [[ -n $CONTAINER_ID ]] && prefix+="$CONTAINER_ID/"
        printf "%s" "$prefix"
    fi
}

PROMPT_SH_PREFIX+='$(_prompt_container)'