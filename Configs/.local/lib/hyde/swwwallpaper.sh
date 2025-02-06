#!/usr/bin/env bash
# shellcheck disable=SC2154

#// lock instance

lockFile="$HYDE_RUNTIME_DIR/$(basename "${0}").lock"
[ -e "${lockFile}" ] && echo "An instance of the script is already running..." && exit 1
touch "${lockFile}"
trap 'rm -f ${lockFile}' EXIT

scrDir="$(dirname "$(realpath "$0")")"
# shellcheck disable=SC1091
source "${scrDir}/globalcontrol.sh"

"${scrDir}/wallpaper.sh" "${@}"
#// check swww daemon

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
