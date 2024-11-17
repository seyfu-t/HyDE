#!/usr/bin/env bash
#|---/ /+------------------+---/ /|#
#|--/ /-| Global functions |--/ /-|#
#|-/ /--| Prasanth Rangan  |-/ /--|#
#|/ /---+------------------+/ /---|#

set -e

scrDir="$(dirname "$(realpath "$0")")"
cloneDir="$(dirname "${scrDir}")"
confDir="${XDG_CONFIG_HOME:-$HOME/.config}"
cacheDir="${XDG_CACHE_HOME:-$HOME/.cache/hyde}"
aurList=(yay paru)
shlList=(zsh fish)

export cloneDir
export confDir
export cacheDir
export aurList
export shlList

pkg_installed() {
    local PkgIn=$1

    if pacman -Qi "${PkgIn}" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

chk_list() {
    vrType="$1"
    local inList=("${@:2}")
    for pkg in "${inList[@]}"; do
        if pkg_installed "${pkg}"; then
            printf -v "${vrType}" "%s" "${pkg}"
            export "${vrType}"
            return 0
        fi
    done
    return 1
}

pkg_available() {
    local PkgIn=$1

    if pacman -Si "${PkgIn}" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

aur_available() {
    local PkgIn=$1

    if ${aurhlpr} -Si "${PkgIn}" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

nvidia_detect() {
    readarray -t dGPU < <(lspci -k | grep -E "(VGA|3D)" | awk -F ': ' '{print $NF}')
    if [ "${1}" == "--verbose" ]; then
        for indx in "${!dGPU[@]}"; do
            echo -e "\033[0;32m[gpu$indx]\033[0m detected // ${dGPU[indx]}"
        done
        return 0
    fi
    if [ "${1}" == "--drivers" ]; then
        while read -r -d ' ' nvcode ; do
            awk -F '|' -v nvc="${nvcode}" 'substr(nvc,1,length($3)) == $3 {split(FILENAME,driver,"/"); print driver[length(driver)],"\nnvidia-utils"}' "${scrDir}"/.nvidia/nvidia*dkms
        done <<< "${dGPU[@]}"
        return 0
    fi
    if grep -iq nvidia <<< "${dGPU[@]}"; then
        return 0
    else
        return 1
    fi
}

prompt_timer() {
    set +e
    unset promptIn
    local timsec=$1
    local msg=$2
    while [[ ${timsec} -ge 0 ]]; do
        echo -ne "\r :: ${msg} (${timsec}s) : "
        read -t 1 -n 1 promptIn
        [ $? -eq 0 ] && break
        ((timsec--))
    done
    export promptIn
    echo ""
    set -e
}

print_log () {
    section=${log_section:-hyde}
    colored=${log_colored:-true}
    [ -n "${section}" ] && echo -ne "\e[32m[$section] \e[0m"
    while (("$#")); do
    # [ "${colored}" == "true" ] 
        case "$1" in
        -r|+r)
            echo -ne "\e[31m$2\e[0m"
            shift 2
            ;; # Red
        -g|+g)
            echo -ne "\e[32m$2\e[0m"
            shift 2
            ;; # Green
        -y|+y)
            echo -ne "\e[33m$2\e[0m"
            shift 2
            ;; # Yellow
        -b|+b)
            echo -ne "\e[34m$2\e[0m"
            shift 2
            ;; # Blue
        -m|+m)
            echo -ne "\e[35m$2\e[0m"
            shift 2
            ;; # Magenta
        -c|+c)
            echo -ne "\e[36m$2\e[0m"
            shift 2
            ;; # Cyan
        -wt|+w)
            echo -ne "\e[37m$2\e[0m"
            shift 2
            ;; # White
        -n|+n)
            echo -ne "\e[96m$2\e[0m"
            shift 2
            ;; # Neon
        -stat)
            echo -ne "\e[46m $2 \e[0m :: "
            shift 2
            ;; # critical         
        -crit)
            echo -ne "\e[41m $2 \e[0m :: "
            shift 2
            ;; # critical         
        -warn)
            echo -ne "\e[43m $2 \e[0m :: "
            shift 2
            ;; # warning
        *)
            echo -ne "$1"
            shift
            ;;
        esac
    done
    echo ""
}