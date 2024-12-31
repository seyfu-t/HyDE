#!/bin/env bash

# Early load to maintain fastfetch speed
if [ -z "${*}" ]; then
  clear
  fastfetch --logo-type kitty
  exit
fi

confDir="${XDG_CONFIG_HOME:-$HOME/.config}"
iconDir="${XDG_DATA_HOME:-$HOME/.local/share}/icons"
image_dirs=()

image_dirs=(
  "${confDir}/fastfetch/logo"
  "${iconDir}/Wallbash-Icon/fastfetch/"
)

# shellcheck source=/dev/null
[ -f "$HYDE_STATE_HOME/staterc" ] && source "$HYDE_STATE_HOME/staterc"
# shellcheck disable=SC1091
[ -f "/etc/os-release" ] && source "/etc/os-release"

if [ -n "${HYDE_THEME}" ] && [ -d "${confDir}/hyde/themes/${HYDE_THEME}" ]; then
  image_dirs+=("${confDir}/hyde/themes/${HYDE_THEME}")
fi

hyde_distro_logo=${iconDir}/Wallbash-Icon/distro/$LOGO
case $1 in
logo)
  (
    [ -f "$hyde_distro_logo" ] && echo "${hyde_distro_logo}"
    find "${image_dirs[@]}" \( -name "*.icon" -o -name "*logo*" -o -name "*.png" \) ! -path "*/wallpapers/*.png" 2>/dev/null
  ) | shuf -n 1

  ;;
help)
  cat <<EOF
Usage: fastfetch [option]

Options:
  logo  Display a random logo
  help  Display this help message
EOF
  ;;
*)
  clear
  fastfetch --logo-type kitty
  ;;
esac
