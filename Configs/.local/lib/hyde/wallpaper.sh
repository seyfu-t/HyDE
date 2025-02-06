#!/usr/bin/env bash
# shellcheck disable=SC2154

#// Set and Cache Wallpaper

Wall_Cache() {
    ln -fs "${wallList[setIndex]}" "${wallSet}"
    ln -fs "${wallList[setIndex]}" "${wallCur}"
    "${scrDir}/swwwallcache.sh" -w "${wallList[setIndex]}" &>/dev/null
    "${scrDir}/swwwallbash.sh" "${wallList[setIndex]}" &
    ln -fs "${thmbDir}/${wallHash[setIndex]}.sqre" "${wallSqr}"
    ln -fs "${thmbDir}/${wallHash[setIndex]}.thmb" "${wallTmb}"
    ln -fs "${thmbDir}/${wallHash[setIndex]}.blur" "${wallBlr}"
    ln -fs "${thmbDir}/${wallHash[setIndex]}.quad" "${wallQad}"
    ln -fs "${dcolDir}/${wallHash[setIndex]}.dcol" "${wallDcl}"
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

#// set variables

scrDir="$(dirname "$(realpath "$0")")"
# shellcheck disable=SC1091
source "${scrDir}/globalcontrol.sh"
wallSet="${HYDE_THEME_DIR}/wall.set"
wallCur="${HYDE_CACHE_HOME}/wall.set"
wallSqr="${HYDE_CACHE_HOME}/wall.sqre"
wallTmb="${HYDE_CACHE_HOME}/wall.thmb"
wallBlr="${HYDE_CACHE_HOME}/wall.blur"
wallQad="${HYDE_CACHE_HOME}/wall.quad"
wallDcl="${HYDE_CACHE_HOME}/wall.dcol"

#// check wall

setIndex=0
[ ! -d "${HYDE_THEME_DIR}" ] && echo "ERROR: \"${HYDE_THEME_DIR}\" does not exist" && exit 0
wallPathArray=("${HYDE_THEME_DIR}")
wallPathArray+=("${WALLPAPER_CUSTOM_PATHS[@]}")
get_hashmap "${wallPathArray[@]}"
[ ! -e "$(readlink -f "${wallSet}")" ] && echo "fixing link :: ${wallSet}" && ln -fs "${wallList[setIndex]}" "${wallSet}"

#// evaluate options
# ...existing code...

# Define long options
LONGOPTS="next,previous,random,set:,get,help"

# Parse options
PARSED=$(
    if getopt --options npro:b:s:gh --longoptions $LONGOPTS --name "$0" -- "$@"; then
        exit 2
    fi
)

# Apply parsed options
eval set -- "$PARSED"

while true; do
    case "$1" in
    -n | --next)
        xtrans=${WALLPAPER_SWWW_TRANSITION_NEXT}
        xtrans="${xtrans:-"grow"}"
        Wall_Change n
        shift
        ;;
    -p | --previous)
        xtrans=${WALLPAPER_SWWW_TRANSITION_PREV}
        xtrans="${xtrans:-"outer"}"}
        Wall_Change p
        shift
        ;;
    -r | --random)
        setIndex=$((RANDOM % ${#wallList[@]}))
        Wall_Cache
        shift
        ;;
    -s | --set)
        if [ -n "$2" ] && [ -f "$2" ]; then
            get_hashmap "$2"
        fi
        Wall_Cache
        shift 2
        ;;
    -b | --backend)
        # Set wallpaper backend to use (swww, hyprpaper, etc.)
        WALLPAPER_BACKEND_LIST+=("${2}")
        shift 2
        ;;
    -o | --output)
        # Set output file for wallpaper
        export wallCur="${2:-${HYDE_CACHE_HOME}/wall.set}"
        shift 2
        ;;
    -h | --help)
        cat <<EOF
Usage: $(basename "$0") --[options] [parameters]
Options:
  -n, --next                Set next wallpaper
  -p, --previous            Set previous wallpaper
  -r, --random              Set random wallpaper
  -s, --set <file>          Set specified wallpaper
  -b, --backend <backend>   Set wallpaper backend to use (swww, hyprpaper, etc.)
  -o, --output <file>       Set output file for wallpaper        
  -h, --help                Display this help message

EOF
        exit 0
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

# Remove duplicates from WALLPAPER_BACKEND_LIST
mapfile -t WALLPAPER_BACKEND_LIST < <(echo "${WALLPAPER_BACKEND_LIST[@]}" | tr ' ' '\n' | sort -u)

if [ -n "${WALLPAPER_BACKEND_LIST[*]}" ]; then
    echo "Using backend: ${WALLPAPER_BACKEND_LIST[*]}"
    for backend in "${WALLPAPER_BACKEND_LIST[@]}"; do
        [ -z "${backend}" ] && continue
        case "${backend}" in
        swww)
            backend_swww
            ;;
        *)
            echo "ERROR: Unsupported backend: ${backend}"
            exit 1
            ;;
        esac
    done
fi
