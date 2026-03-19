
_prompt_container() {
    if [[ -f /run/.containerenv ]]; then
        local prefix="ctr/"
        [[ -n $container ]] && prefix+="$container/"
        [[ -f /run/.toolboxenv ]] && prefix+="tlbx/"
        [[ -n $CONTAINER_ID ]] && prefix+="$CONTAINER_ID/"
        tput setaf 7
        tput bold
        printf "%s" "$prefix"
        tput sgr0
    fi
}

PROMPT_SH_PREFIX+='$(_prompt_container)'