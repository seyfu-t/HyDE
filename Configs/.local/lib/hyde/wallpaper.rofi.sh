#!/usr/bin/env bash

#// set rofi scaling

# #// launch rofi menu

# # shellcheck disable=SC2154
# currentWall="$(basename "$(readlink "${HYDE_THEME_DIR}/wall.set")")"
# wallPathArray=("${HYDE_THEME_DIR}")
# wallPathArray+=("${WALLPAPER_CUSTOM_PATHS[@]}")
# get_hashmap "${wallPathArray[@]}"
# wallListBase=()
# # shellcheck disable=SC2154
# for wall in "${wallList[@]}"; do
#     wallListBase+=("${wall##*/}") # get the basename // bash way
# done

# # shellcheck disable=SC2154
# # rofiSel=$(
# echo "${rofi_list}" | rofi -dmenu \
#     -theme-str "${font_override}" \
#     -theme-str "${r_override}" \
#     -theme "${ROFI_WALLPAPER_STYLE:-selector}" \
#     -select "${currentWall}" | xargs
# # )

# main() {
#     #// set full cache variables
#     if [ -z "$wallpaper_backend" ]; then
#         print_log -err "wallpaper" " No backend specified"
#         print_log -err "wallpaper" " Please specify a backend, try '--backend swww'"
#         exit 1
#     fi

#     #// apply wallpaper

#     if [ -n "${rofiSel}" ]; then
#         for i in "${!wallPathArray[@]}"; do
#             setWall=$(find "${wallPathArray[i]}" -type f -name "${rofiSel}")
#             [ -z "${setWall}" ] || break
#         done
#         if [ -n "${setWall}" && -n "${wallpaper_backend}" ]; then
#             "${scrDir}/wallpaper.sh" -s "${setWall}" --backend "${wallpaper_backend}" --global
#             notify-send -a "HyDE Alert" -i "${thmbDir}/$(set_hash "${setWall}").sqre" " ${rofiSel}"
#         else
#             notify-send -a "HyDE Alert" "Wallpaper not found"
#         fi

#     fi
# }

# main
