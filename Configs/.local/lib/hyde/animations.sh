#!/usr/bin/env bash

# Set variables
scrDir=$(dirname "$(realpath "$0")")
scrDir="${scrDir:-$HOME/.config/hyde}"
# shellcheck disable=SC1091
source "$scrDir/globalcontrol.sh"
confDir="${confDir:-$XDG_CONFIG_HOME}"
animations_dir="$confDir/hypr/animations"
rofi_theme="$confDir/rofi/clipboard.rasi"

# Set rofi scaling
[[ "${rofiScale}" =~ ^[0-9]+$ ]] || rofiScale=10
r_scale="configuration {font: \"JetBrainsMono Nerd Font ${rofiScale}\";}"
hypr_border=${hypr_border:-"$(hyprctl -j getoption decoration:rounding | jq '.int')"}
wind_border=$((hypr_border * 3 / 2))
elem_border=$((hypr_border == 0 ? 5 : hypr_border))

# Evaluate spawn position
readarray -t curPos < <(hyprctl cursorpos -j | jq -r '.x,.y')
readarray -t monRes < <(hyprctl -j monitors | jq '.[] | select(.focused==true) | .width,.height,.scale,.x,.y')
readarray -t offRes < <(hyprctl -j monitors | jq -r '.[] | select(.focused==true).reserved | map(tostring) | join("\n")')
monRes[2]="${monRes[2]//./}"
monRes[0]=$((monRes[0] * 100 / monRes[2]))
monRes[1]=$((monRes[1] * 100 / monRes[2]))
curPos[0]=$((curPos[0] - monRes[3]))
curPos[1]=$((curPos[1] - monRes[4]))

if [ "${curPos[0]}" -ge "$((monRes[0] / 2))" ]; then
    x_pos="east"
    x_off="-$((monRes[0] - curPos[0] - offRes[2]))"
else
    x_pos="west"
    x_off="$((curPos[0] - offRes[0]))"
fi

if [ "${curPos[1]}" -ge "$((monRes[1] / 2))" ]; then
    y_pos="south"
    y_off="-$((monRes[1] - curPos[1] - offRes[3]))"
else
    y_pos="north"
    y_off="$((curPos[1] - offRes[1]))"
fi
hypr_width=${hypr_width:-"$(hyprctl -j getoption general:border_size | jq '.int')"}
r_override="window{location:${x_pos} ${y_pos};anchor:${x_pos} ${y_pos};x-offset:${x_off}px;y-offset:${y_off}px;border:${hypr_width}px;border-radius:${wind_border}px;} wallbox{border-radius:${elem_border}px;} element{border-radius:${elem_border}px;}"

# Ensure the animations directory exists
if [ ! -d "$animations_dir" ]; then
    notify-send -i "preferences-desktop-display" "Error" "Animations directory does not exist at $animations_dir"
    exit 1
fi

# List available .conf files in animations directory
animation_files=$(find "$animations_dir" -name "*.conf" ! -name "disable.conf" ! -name "wallbash.conf" 2>/dev/null | sed 's/\.conf$//')

if [ -z "$animation_files" ]; then
    notify-send -i "preferences-desktop-display" "Error" "No .conf files found in $animations_dir"
    exit 1
fi

animation_files="Disable Animation
Theme Preference
$animation_files"

# Display options using Rofi with custom scaling, positioning, and placeholder
selected_animation=$(awk -F/ '{print $NF}' <<<"$animation_files" |
    rofi -dmenu \
        -p "Select animation" \
        -theme-str "entry { placeholder: \"Select animation...\"; }" \
        -theme-str "${r_scale}" \
        -theme-str "${r_override}" \
        -theme "$rofi_theme")

# Exit if no selection was made
if [ -z "$selected_animation" ]; then
    exit 0
fi
case $selected_animation in
"Disable Animation")
    selected_animation="disable"
    ;;
"Theme Preference")
    selected_animation="wallbash"
    ;;
esac

animations_conf="$confDir/hypr/hyde.conf"
# Update the animations.conf file
# shellcheck disable=SC2016
if grep -qE '\$ANIMATION\s*=\s*.*' "${animations_conf}"; then
    sed -i "s/\$ANIMATION\s*=\s*.*/\$ANIMATION=$selected_animation/" "$animations_conf"
else
    echo "\$ANIMATION=$selected_animation" >>"$animations_conf"
fi

# Notify the user
notify-send -i "preferences-desktop-display" "Animation:" "$selected_animation"
