#!/usr/bin/env bash

# shellcheck source=$HOME/.local/bin/hyde-shell
# shellcheck disable=SC1091
if ! source "$(which hyde-shell)"; then
    echo "[wallbash] code :: Error: hyde-shell not found."
    echo "[wallbash] code :: Is HyDE installed?"
    exit 1
fi

# Set variables
confDir="${confDir:-$XDG_CONFIG_HOME}"
animations_dir="$confDir/hypr/animations"
rofi_config="$confDir/rofi/clipboard.rasi"

# Set rofi scaling
[[ "${rofiScale}" =~ ^[0-9]+$ ]] || rofiScale=10
r_scale="configuration {font: \"JetBrainsMono Nerd Font ${rofiScale}\";}"

# Window and element styling
hypr_border=${hypr_border:-"$(hyprctl -j getoption decoration:rounding | jq '.int')"}
wind_border=$((hypr_border * 3 / 2))
elem_border=$((hypr_border == 0 ? 5 : hypr_border))
hypr_width=${hypr_width:-"$(hyprctl -j getoption general:border_size | jq '.int')"}
r_override="window{border:${hypr_width}px;border-radius:${wind_border}px;} wallbox{border-radius:${elem_border}px;} element{border-radius:${elem_border}px;}"

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
        -theme-str "$(get_rofi_follow_mouse)" \
        -theme "$rofi_config")

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
