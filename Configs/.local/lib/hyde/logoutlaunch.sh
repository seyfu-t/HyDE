#!/usr/bin/env bash


#// Check if wlogout is already running

if pgrep -x "wlogout" > /dev/null
then
    pkill -x "wlogout"
    exit 0
fi


#// set file variables

scrDir=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1091
source "$scrDir/globalcontrol.sh"
[ -z "${1}" ] || wlogoutStyle="${1}"
confDir="${confDir:-$HOME/.config}"
wLayout="${confDir}/wlogout/layout_${wlogoutStyle}"
wlTmplt="${confDir}/wlogout/style_${wlogoutStyle}.css"

if [ ! -f "${wLayout}" ] || [ ! -f "${wlTmplt}" ] ; then
    echo "ERROR: Config ${wlogoutStyle} not found..."
    wlogoutStyle=1
    wLayout="${confDir}/wlogout/layout_${wlogoutStyle}"
    wlTmplt="${confDir}/wlogout/style_${wlogoutStyle}.css"
fi


#// detect monitor res

x_mon=$(hyprctl -j monitors | jq '.[] | select(.focused==true) | .width')
y_mon=$(hyprctl -j monitors | jq '.[] | select(.focused==true) | .height')
hypr_scale=$(hyprctl -j monitors | jq '.[] | select (.focused == true) | .scale' | sed 's/\.//')


#// scale config layout and style

case "${wlogoutStyle}" in
    1)  wlColms=6
        export mgn=$(( y_mon * 28 / hypr_scale ))
        export hvr=$(( y_mon * 23 / hypr_scale )) ;;
    2)  wlColms=2
        export x_mgn=$(( x_mon * 35 / hypr_scale ))
        export y_mgn=$(( y_mon * 25 / hypr_scale ))
        export x_hvr=$(( x_mon * 32 / hypr_scale ))
        export y_hvr=$(( y_mon * 20 / hypr_scale )) ;;
esac


#// scale font size

export fntSize=$(( y_mon * 2 / 100 ))


#// detect wallpaper brightness

cacheDir="${cacheDir:$XDG_CACHE_HOME/hyde}"
dcol_mode="${dcol_mode:-dark}"
# shellcheck disable=SC1091
[ -f "${cacheDir}/wall.dcol" ] && source "${cacheDir}/wall.dcol"

#  Theme mode: detects the color-scheme set in hypr.theme and falls back if nothing is parsed.
enableWallDcol="${enableWallDcol:-1}"
if [ "${enableWallDcol}" -eq 0 ]; then
hydeThemeDir="${hydeThemeDir:-$confDir/hyde/themes/$hydeTheme}"
dcol_mode=$(get_hyprConf "COLOR_SCHEME")
dcol_mode=${dcol_mode#prefer-}
# shellcheck disable=SC1091
[ -f "${hydeThemeDir}/theme.dcol" ] && source "${hydeThemeDir}/theme.dcol"
fi
{ [ "${dcol_mode}" == "dark" ] && export BtnCol="white" ;} || export BtnCol="black"


#// eval hypr border radius

hypr_border="${hypr_border:-10}"
export active_rad=$(( hypr_border * 5 ))
export button_rad=$(( hypr_border * 8 ))


#// eval config files

wlStyle="$(envsubst < "${wlTmplt}")"


#// launch wlogout

wlogout -b "${wlColms}" -c 0 -r 0 -m 0 --layout "${wLayout}" --css <(echo "${wlStyle}") --protocol layer-shell

