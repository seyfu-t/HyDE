#!/usr/bin/env bash
#|---/ /+---------------------------+---/ /|#
#|--/ /-| Script to configure shell |--/ /-|#
#|-/ /--| Prasanth Rangan           |-/ /--|#
#|/ /---+---------------------------+/ /---|#

scrDir=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1091
if ! source "${scrDir}/global_fn.sh"; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

# shellcheck disable=SC2154
if chk_list "myShell" "${shlList[@]}"; then
    print_log -g "[SHELL] " -b "detected :: " "${myShell}"
else
    print_log -g "[SHELL] " -r "error :: " "no shell found..."
    exit 1
fi

# add zsh plugins
# TODO Nuke this and try to remove oh-my-zsh
if pkg_installed zsh; then

    #? Optional: oh-my-zsh 
    if pkg_installed oh-my-zsh-git; then

        # set variables
        Zsh_rc="${ZDOTDIR:-$HOME}/.zshrc"
        Zsh_Path="/usr/share/oh-my-zsh"
        Zsh_Plugins="$Zsh_Path/custom/plugins"
        Fix_Completion=""

        # generate plugins from list
        while read -r r_plugin; do
            z_plugin=$(awk -F '/' '{print $NF}' <<< "${r_plugin}")
            if [ "${r_plugin:0:4}" == "http" ] && [ ! -d "${Zsh_Plugins}/${z_plugin}" ]; then
                sudo git clone "${r_plugin}" "${Zsh_Plugins}/${z_plugin}"
            fi
            if [ "${z_plugin}" == "zsh-completions" ] && [ "$(grep 'fpath+=.*plugins/zsh-completions/src' "${Zsh_rc}" | wc -l)" -eq 0 ]; then
                Fix_Completion='\nfpath+=${ZSH_CUSTOM:-${ZSH:-/usr/share/oh-my-zsh}/custom}/plugins/zsh-completions/src'
            else
                [ -z "${z_plugin}" ] || w_plugin+=" ${z_plugin}"
            fi
        done < <(cut -d '#' -f 1 "${scrDir}/restore_zsh.lst" | sed 's/ //g')

        # update plugin array in zshrc
        print_log -g "[SHELL] " -b "installing :: " "plugins (${w_plugin} )"
        sed -i "/^plugins=/c\plugins=(${w_plugin} )${Fix_Completion}" "${Zsh_rc}"
    fi
fi

# set shell
if [[ "$(grep "/${USER}:" /etc/passwd | awk -F '/' '{print $NF}')" != "${myShell}" ]]; then
    print_log -g "[SHELL] " -b "change :: " "shell to ${myShell}..."
    chsh -s "$(which "${myShell}")"
else
    print_log -y "[SHELL] " -y "exist :: " "${myShell} is already set as shell..."
fi
