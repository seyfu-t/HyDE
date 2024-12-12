#! /bin/bash

# source variables
confDir="${confDir:-$HOME/.config}"
cacheDir="${cacheDir:-$HOME/.cache/hyde}"
WALLPAPER="${cacheDir}/wall.set"

# Converts and ensures background to be a png
fn_background() {
    BG="${cacheDir}/wall.set.png"
    mime=$(file --mime-type "${WALLPAPER}" | grep "image/png")
    rm "${BG}"
    cp -f "${WALLPAPER}" "${BG}"
    #? Run this in the background because converting takes time
    ([[ -z ${mime} ]] && magick "${BG}"[0] "${BG}") &
}

mpris_thumb() { # Generate thumbnail for mpris
    artUrl=$(playerctl -p spotify metadata --format '{{mpris:artUrl}}')
    [ "${artUrl}" == "$(cat "${THUMB}".lnk)" ] && [ -f "${THUMB}".png ] && exit 0
    echo "${artUrl}" >"${THUMB}".lnk
    curl -Lso "${THUMB}".art "$artUrl"
    magick "${THUMB}.art" -quality 50 "${THUMB}.png"
    pkill -USR2 hyprlock # updates the mpris thumbnail
}

fn_mpris() {
    THUMB="${cacheDir}/landing/mpris"
    if [ "$(playerctl -p spotify status)" == "Playing" ]; then
        playerctl -p spotify metadata --format '{{title}}    {{artist}}'
        mpris_thumb
    else

        if [ -f "$HOME/.face.icon" ]; then
            cp -f "$HOME/.face.icon" "${THUMB}".png
        else
            cp "$XDG_DATA_HOME/icons/Wallbash-Icon/hyde.png" "${THUMB}".png
        fi
        pkill -USR2 hyprlock # updates the mpris thumbnail
        return 1
    fi
}

fn_cava() {

    :

}

fn_art() {
    echo "$XDG_CACHE_HOME/hyde/landing/mpris.art"
}

if declare -f "fn_${1}" >/dev/null; then
    "fn_${1}"
else
    hyprlock
fi
