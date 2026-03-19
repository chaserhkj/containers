# Prompt-setting scripts suitable for both zsh and bash

# Do not execute this script in zsh emulation context
if [ -n "$ZSH_VERSION" ] && [ "$(emulate)" != "zsh" ]; then
    return 0
fi

_prompt_sep() {
    printf "%.0s$1" $(seq 1 $((COLUMNS - 1)))
}

_prompt_time() {
    printf "%*s" $COLUMNS "($(date +"%F %H:%MT%:::z"))"
}

_prompt_load() {
    printf "(%s/%s)" "$(awk '{ print $1, $2, $3 }' < /proc/loadavg)" "$(grep ^processor /proc/cpuinfo|wc -l)"
}

_prompt_mem() {
    printf "(%s)" "$(free | awk '/Mem:/ {printf("%.0f%%", $3/$2*100)}')"
}

_get_prompt() {
    local last_code=$?
    local _reset _dim _bold _set_cur _reset_cur _blue _green _red _yellow
    _reset="\[$(tput sgr0)\]"
    _dim="\[$(tput dim)\]"
    _bold="\[$(tput bold)\]"
    _set_cur="\[$(tput sc)"
    _reset_cur="$(tput rc)\]"
    _blue="\[$(tput setaf 4)\]"
    _green="\[$(tput setaf 2)\]"
    _red="\[$(tput setaf 1)\]"
    _yellow="\[$(tput setaf 3)\]"
    _purple="\[$(tput setaf 5)\]"
    _cyan="\[$(tput setaf 6)\]"
    _white="\[$(tput setaf 7)\]"
    # Separator
    _prompt_="$_dim""$(_prompt_sep _)$_reset"
    _prompt_+="$PROMPT_STATUS_PREFIX"
    # Status line
    # Time
    _prompt_+='\n'"$_set_cur$_blue$(_prompt_time)$_reset$_reset_cur"
    # Root indicator
    local _user_color _sym _host_color _ssh_color
    if [[ $UID == 0 ]]; then
        _user_color="$_red"
        _sym='#'
    if [[ $USER != root ]]; then
            _user_color="$_yellow"
        _sym='*'
    fi
    else
        _user_color="$_green"
    _sym='$'
    fi
    if [[ -n $PROMPT_HOST_COLOR_CODE ]]; then
        _host_color="\[$(tput setaf $PROMPT_HOST_COLOR_CODE)\]"
        _ssh_color=$_host_color
    else
        _host_color=$_user_color
        _ssh_color=$_white
    fi
    local _shell
    [[ -n $BASH ]] && _shell=bash
    [[ -n $ZSH_NAME ]] && _shell=zsh
    [[ -z $_shell ]] && _shell='?sh'
    _prompt_+="$_user_color$_bold"'['"$_reset"
    [[ -n $PROMPT_SH_PREFIX ]] && _prompt_+="$PROMPT_SH_PREFIX"
    _prompt_+="$_user_color$_bold$_shell"'] '"$_reset"
    # Load
    _prompt_+="$_blue$_bold$(_prompt_load)$_reset"
    # Mem
    _prompt_+="$_blue$_bold$(_prompt_mem) $_reset"
    [[ -n $SSH_CLIENT ]] && _prompt_+="$_ssh_color$_bold"'['"$(echo $SSH_CLIENT|cut -d' ' -f1)"' ->]'" $_reset"
    # Extra contexts
    _prompt_+="$_bold$PROMPT_CONTEXT$_reset"
    _prompt_+="$PROMPT_STATUS_POSTFIX"
    # Context line
    # User@Host
    _prompt_+='\n'"$_bold$_user_color"'[${USER}@'"$_host_color"'\h'"$_user_color"'] '"$_reset"
    # PWD
    _prompt_+="$_user_color"'\w'"$_reset"'\n'
    # Prompt line
    _prompt_+="$_bold$_sym $_reset"
}

_prompt() {
    _get_prompt
    PS1="$_prompt_"
}

if [ -n "$BASH_VERSION" ]; then
    PROMPT_COMMAND+=( _prompt )
    # Separator before each output 
    PS0='$(tput dim; _prompt_sep -; tput sgr0;)\n'
elif [ -n "$ZSH_VERSION" ]; then
    # With bash this is provided by BLE, but for zsh we do it here
    return_code_prompt() {
        local last_code=$?
        if [[ $last_code != 0 ]]; then
            tput setaf 1
            echo "[return $last_code]"
            tput sgr0
        fi
    }
    precmd_prompt() {
        _get_prompt
        _prompt_=$(echo $_prompt_ | sed 's/%/%%/g')
        _prompt_=$(echo $_prompt_ | sed 's/\\\[/%{/g')
        _prompt_=$(echo $_prompt_ | sed 's/\\\]/%}/g')
        _prompt_=$(echo $_prompt_ | sed 's/\\h/%m/g')
        _prompt_=$(echo $_prompt_ | sed 's/\\w/%~/g')
        PROMPT=$_prompt_
    }
    preexec_prompt() {
        tput dim
        _prompt_sep -
        echo
        tput sgr0
    }
    precmd_functions=(return_code_prompt precmd_prompt "${precmd_functions[@]}")
    preexec_functions=(preexec_prompt "${preexec_functions[@]}")
fi
