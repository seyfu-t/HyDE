#!/usr/bin/env bash
# shellcheck disable=SC2154

scrDir="$(dirname "$(realpath "$0")")"
# shellcheck disable=SC1091
source "${scrDir}/globalcontrol.sh"

# // Help message
show_help() {
    cat <<EOF
Usage: $(basename "$0") --[options|flags] [parameters]
options:
    -n, --next                Set next wallpaper
    -p, --previous            Set previous wallpaper
    -r, --random              Set random wallpaper
    -s, --set <file>          Set specified wallpaper
    -g, --get                 Get current wallpaper of specified backend
    -o, --output <file>       Copy current wallpaper to specified file
    -h, --help                Display this help message

flags:
    -b, --backend <backend>   Set wallpaper backend to use (swww, hyprpaper, etc.)
    -G, --global              Set wallpaper as global

notes: 
       --backend <backend> is also use to cache wallpapers/background images e.g. hyprlock
           when '--backend hyprlock' is used, the wallpaper will be cached in
           ~/.cache/hyde/wall.hyprlock.png

       --global flag is used to set the wallpaper as global, this means all
         thumbnails will be updated to reflect the new wallpaper

       --output <path> is used to copy the current wallpaper to the specified path
            We can use this to have a copy of the wallpaper to '/var/tmp' where sddm or
            any systemwide application can access it  
EOF
    exit 0
}
#// Set and Cache Wallpaper

Wall_Cache() {
    ln -fs "${wallList[setIndex]}" "${wallSet}"
    ln -fs "${wallList[setIndex]}" "${wallCur}"
    if [ "${set_as_global}" == "true" ]; then
        print_log -sec "wallpaper" "Setting Wallpaper as global"
        "${scrDir}/swwwallcache.sh" -w "${wallList[setIndex]}" &>/dev/null
        "${scrDir}/swwwallbash.sh" "${wallList[setIndex]}" &
        ln -fs "${thmbDir}/${wallHash[setIndex]}.sqre" "${wallSqr}"
        ln -fs "${thmbDir}/${wallHash[setIndex]}.thmb" "${wallTmb}"
        ln -fs "${thmbDir}/${wallHash[setIndex]}.blur" "${wallBlr}"
        ln -fs "${thmbDir}/${wallHash[setIndex]}.quad" "${wallQad}"
        ln -fs "${dcolDir}/${wallHash[setIndex]}.dcol" "${wallDcl}"
    fi

}

Wall_Change() {
    curWall="$(set_hash "${wallSet}")"
    for i in "${!wallHash[@]}"; do
        if [ "${curWall}" == "${wallHash[i]}" ]; then
            if [ "${1}" == "n" ]; then
                setIndex=$(((i + 1) % ${#wallList[@]}))
            elif [ "${1}" == "p" ]; then
                setIndex=$((i - 1))
            fi
            break
        fi
    done
    Wall_Cache
}

# interfacing with swww backend
backend_swww() {
    lockFile="$HYDE_RUNTIME_DIR/$(basename "${0}").lock"
    [ -e "${lockFile}" ] && echo "An instance of the script is already running..." && exit 1
    touch "${lockFile}"
    trap 'rm -f ${lockFile}' EXIT

    if ! swww query &>/dev/null; then
        swww-daemon --format xrgb &
        disown
        swww query && swww restore
    fi

    #// set defaults
    xtrans=${WALLPAPER_SWWW_TRANSITION_DEFAULT}
    [ -z "${xtrans}" ] && xtrans="grow"
    [ -z "${wallFramerate}" ] && wallFramerate=60
    [ -z "${wallTransDuration}" ] && wallTransDuration=0.4

    #// apply wallpaper
    # TODO: add support for other backends
    print_log -sec "wallpaper" -stat "apply" "$(readlink -f "$HOME/.cache/hyde/wall.set")"
    swww img "$(readlink "$HOME/.cache/hyde/wall.set")" --transition-bezier .43,1.19,1,.4 --transition-type "${xtrans}" --transition-duration "${wallTransDuration}" --transition-fps "${wallFramerate}" --invert-y --transition-pos "$(hyprctl cursorpos | grep -E '^[0-9]' || echo "0,0")" &

}

#// evaluate options

if [ -z "${*}" ]; then
    echo "No arguments provided"
    show_help
fi

# Define long options
LONGOPTS="global,next,previous,random,set:,backend:,get,output,help"

# Parse options
PARSED=$(
    if getopt --options Gnprb:s:go:h --longoptions $LONGOPTS --name "$0" -- "$@"; then
        exit 2
    fi
)

wallpaper_setter_flag=

# Apply parsed options
eval set -- "$PARSED"
while true; do
    case "$1" in
    -G | --global)
        set_as_global=true
        shift
        ;;
    -n | --next)
        wallpaper_setter_flag=n
        shift
        ;;
    -p | --previous)
        wallpaper_setter_flag=p
        shift
        ;;
    -r | --random)
        wallpaper_setter_flag=r
        shift
        ;;
    -s | --set)
        wallpaper_setter_flag=s
        wallpaper_path="${2}"
        shift 2
        ;;
    -g | --get)
        wallpaper_setter_flag=g
        shift
        ;;
    -b | --backend)
        # Set wallpaper backend to use (swww, hyprpaper, etc.)
        walllpaper_backend="${2:-"$WALLPAPER_BACKEND"}"
        shift 2
        ;;
    -o | --output)
        # Accepts wallpaper output path
        wallpaper_setter_flag=o
        walllpaper_output="${2}"
        shift 2
        ;;
    -h | --help)
        show_help
        ;;
    --)
        shift
        break
        ;;
    *)
        echo "Invalid option: $1"
        echo "Try '$(basename "$0") --help' for more information."
        exit 1
        ;;
    esac
done

main() {
    #// set full cache variables
    if [ -z "$walllpaper_backend" ] && [ "$wallpaper_setter_flag" != "o" ]; then
        print_log -err "wallpaper" " No backend specified"
        print_log -err "wallpaper" " Please specify a backend, try '--backend swww'"
        exit 1
    fi

    #  If wallpaper is used for thumbnails, set the following variables
    if [ "$set_as_global" == "true" ]; then
        wallSet="${HYDE_THEME_DIR}/wall.set"
        wallCur="${HYDE_CACHE_HOME}/wall.set"
        wallSqr="${HYDE_CACHE_HOME}/wall.sqre"
        wallTmb="${HYDE_CACHE_HOME}/wall.thmb"
        wallBlr="${HYDE_CACHE_HOME}/wall.blur"
        wallQad="${HYDE_CACHE_HOME}/wall.quad"
        wallDcl="${HYDE_CACHE_HOME}/wall.dcol"
    elif [ -n "${walllpaper_backend}" ]; then
        mkdir -p "${HYDE_CACHE_HOME}/wallpapers"
        wallCur="${HYDE_CACHE_HOME}/wallpapers/${walllpaper_backend}.png"
        wallSet="${HYDE_THEME_DIR}/wall.${walllpaper_backend}.png"
    else
        wallSet="${HYDE_THEME_DIR}/wall.set"
    fi

    #// check wall

    setIndex=0
    [ ! -d "${HYDE_THEME_DIR}" ] && echo "ERROR: \"${HYDE_THEME_DIR}\" does not exist" && exit 0
    wallPathArray=("${HYDE_THEME_DIR}")
    wallPathArray+=("${WALLPAPER_CUSTOM_PATHS[@]}")
    get_hashmap "${wallPathArray[@]}"
    [ ! -e "$(readlink -f "${wallSet}")" ] && echo "fixing link :: ${wallSet}" && ln -fs "${wallList[setIndex]}" "${wallSet}"

    if [ -n "${wallpaper_setter_flag}" ]; then
        case "${wallpaper_setter_flag}" in
        n)
            xtrans=${WALLPAPER_SWWW_TRANSITION_NEXT}
            xtrans="${xtrans:-"grow"}"
            Wall_Change n
            ;;
        p)
            xtrans=${WALLPAPER_SWWW_TRANSITION_PREV}
            xtrans="${xtrans:-"outer"}"}
            wallpaper_setter_flag=p
            Wall_Change p
            ;;
        r)
            setIndex=$((RANDOM % ${#wallList[@]}))
            Wall_Cache
            ;;
        s)
            if [ -n "${wallpaper_path}" ] && [ -f "${wallpaper_path}" ]; then
                get_hashmap "${wallpaper_path}"
            fi
            Wall_Cache
            ;;
        g)
            if [ ! -e "${wallSet}" ]; then
                print_log -err "wallpaper" "Wallpaper not found: ${wallSet}"
                exit 1
            fi
            realpath "${wallSet}"
            exit 0
            ;;
        o)
            if [ -n "${walllpaper_output}" ]; then
                print_log -sec "wallpaper" "Current wallpaper copied to: ${walllpaper_output}"
                cp -f "${wallSet}" "${walllpaper_output}"
            fi
            ;;
        esac
    fi

    # Apply wallpaper to  backend
    if [ -n "${walllpaper_backend}" ]; then
        print_log -sec "wallpaper" "Using backend: ${walllpaper_backend}"
        case "${walllpaper_backend}" in
        swww)
            backend_swww
            ;;
        esac
    fi
}

main
