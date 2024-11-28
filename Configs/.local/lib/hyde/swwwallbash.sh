#!/usr/bin/env bash
# shellcheck disable=SC2154

#// set variables

scrDir="$(dirname "$(realpath "$0")")"
export scrDir
# shellcheck disable=SC1091
source "${scrDir}/globalcontrol.sh"
wallbashImg="${1}"

# Parse arguments
dcol_colors=""
while [[ $# -gt 0 ]]; do
    case "$1" in
    --dcol)
        dcol_colors="$2"
        if [ -f "${dcol_colors}" ]; then
            echo "[Source] ${dcol_colors}"
            # shellcheck disable=SC1090
            source "${dcol_colors}"
            shift 2
        else
            dcol_colors="$(find "${dcolDir}" -type f -name "*.dcol" | shuf -n 1)"
            echo "[Dcol Colors] ${dcol_colors}"
            shift
        fi
        ;;
    --wall)
        wallbashImg="$2"
        shift 2
        ;;
    --single)
        [ -f "${wallbashImg}" ] || wallbashImg="${cacheDir}/wall.set"
        single_template="$2"
        echo "[wallbash] Single template: ${single_template}"
        echo "[wallbash] Wallpaper: ${wallbashImg}"
        shift 2
        #     ;;
        # --mode)
        #     enableWallDcol="$2"
        #     shift 2
        ;;
    -*)
        echo "Usage: $0 [--dcol <mode>] [--wall <image>] [--single] [--mode <mode>] [--help]"
        exit 0
        ;;
    *) break ;;
    esac
done

#// validate input

if [ -z "${wallbashImg}" ] || [ ! -f "${wallbashImg}" ]; then
    echo "Error: Input wallpaper not found!"
    exit 1
fi
# shellcheck disable=SC2154
wallbashOut="${dcolDir}/$(set_hash "${wallbashImg}").dcol"

if [ ! -f "${wallbashOut}" ]; then
    "${scrDir}/swwwallcache.sh" -w "${wallbashImg}" &>/dev/null
fi

set -a
# shellcheck disable=SC1090
source "${wallbashOut}"
# shellcheck disable=SC2154
if [ -f "${hydeThemeDir}/theme.dcol" ] && [ "${enableWallDcol}" -eq 0 ]; then
    # shellcheck disable=SC1091
    source "${hydeThemeDir}/theme.dcol"
    print_log -sec "wallbash" -stat "override" "dominant colors from ${hydeTheme} theme"
    print_log -sec "wallbash" -stat " NOTE" "Remove \"${hydeThemeDir}/theme.dcol\" to use wallpaper dominant colors"
fi
# shellcheck disable=SC2154
[ "${dcol_mode}" == "dark" ] && dcol_invt="light" || dcol_invt="dark"
set +a

if [ -z "$gtkTheme" ]; then
    if [ "${enableWallDcol}" -eq 0 ]; then
        gtkTheme="$(get_hyprConf "GTK_THEME")"
    else
        gtkTheme="Wallbash-Gtk"
    fi
fi
[ -z "$gtkIcon" ] && gtkIcon="$(get_hyprConf "ICON_THEME")"
[ -z "$cursorTheme" ] && cursorTheme="$(get_hyprConf "CURSOR_THEME")"
export gtkTheme gtkIcon cursorTheme

#// deploy wallbash colors

fn_wallbash() {
    local tplt="${1}"
    # shellcheck disable=SC1091
    # shellcheck disable=SC2154
    [ -f "${hydeConfDir}/hyderc" ] && source "${hydeConfDir}/hyderc"
    # Skips the the template declared in ./hyderc
    if [[ -n "${skip_wallbash[*]}" ]]; then
        for skip in "${skip_wallbash[@]}"; do
            if [[ "${tplt}" =~ ${skip} ]]; then
                print_log -sec "wallbash" -warn "skip '$skip' template " "Template: ${tplt}"
                return 0
            fi
        done
    fi
    eval target="$(head -1 "${tplt}" | awk -F '|' '{print $1}')"
    [ ! -d "$(dirname "${target}")" ] && print_log -sec "wallbash" -warn "skip 'missing directory'" "${target} // Do you have the dependency installed?" && return 0
    wallbashScripts="${tplt%%hyde/wallbash*}hyde/wallbash/scripts"
    export wallbashScripts confDir hydeConfDir cacheDir thmbDir dcolDir iconsDir themesDir fontsDir walbashDirs enableWallDcol hydeThemeDir hydeTheme gtkIcon gtkTheme cursorTheme
    export -f pkg_installed print_log
    appexe="$(head -1 "${tplt}" | awk -F '|' '{print $2}')"
    sed '1d' "${tplt}" >"${target}"

    if [[ ${revert_colors} -eq 1 ]] || [[ "${enableWallDcol}" -eq 2 && "${dcol_mode}" == "light" ]] || [[ "${enableWallDcol}" -eq 3 && "${dcol_mode}" == "dark" ]]; then
        sed -i 's/<wallbash_mode>/'"${dcol_invt}"'/g
                s/<wallbash_pry1>/'"${dcol_pry4}"'/g
                s/<wallbash_txt1>/'"${dcol_txt4}"'/g
                s/<wallbash_1xa1>/'"${dcol_4xa9}"'/g
                s/<wallbash_1xa2>/'"${dcol_4xa8}"'/g
                s/<wallbash_1xa3>/'"${dcol_4xa7}"'/g
                s/<wallbash_1xa4>/'"${dcol_4xa6}"'/g
                s/<wallbash_1xa5>/'"${dcol_4xa5}"'/g
                s/<wallbash_1xa6>/'"${dcol_4xa4}"'/g
                s/<wallbash_1xa7>/'"${dcol_4xa3}"'/g
                s/<wallbash_1xa8>/'"${dcol_4xa2}"'/g
                s/<wallbash_1xa9>/'"${dcol_4xa1}"'/g
                s/<wallbash_pry2>/'"${dcol_pry3}"'/g
                s/<wallbash_txt2>/'"${dcol_txt3}"'/g
                s/<wallbash_2xa1>/'"${dcol_3xa9}"'/g
                s/<wallbash_2xa2>/'"${dcol_3xa8}"'/g
                s/<wallbash_2xa3>/'"${dcol_3xa7}"'/g
                s/<wallbash_2xa4>/'"${dcol_3xa6}"'/g
                s/<wallbash_2xa5>/'"${dcol_3xa5}"'/g
                s/<wallbash_2xa6>/'"${dcol_3xa4}"'/g
                s/<wallbash_2xa7>/'"${dcol_3xa3}"'/g
                s/<wallbash_2xa8>/'"${dcol_3xa2}"'/g
                s/<wallbash_2xa9>/'"${dcol_3xa1}"'/g
                s/<wallbash_pry3>/'"${dcol_pry2}"'/g
                s/<wallbash_txt3>/'"${dcol_txt2}"'/g
                s/<wallbash_3xa1>/'"${dcol_2xa9}"'/g
                s/<wallbash_3xa2>/'"${dcol_2xa8}"'/g
                s/<wallbash_3xa3>/'"${dcol_2xa7}"'/g
                s/<wallbash_3xa4>/'"${dcol_2xa6}"'/g
                s/<wallbash_3xa5>/'"${dcol_2xa5}"'/g
                s/<wallbash_3xa6>/'"${dcol_2xa4}"'/g
                s/<wallbash_3xa7>/'"${dcol_2xa3}"'/g
                s/<wallbash_3xa8>/'"${dcol_2xa2}"'/g
                s/<wallbash_3xa9>/'"${dcol_2xa1}"'/g
                s/<wallbash_pry4>/'"${dcol_pry1}"'/g
                s/<wallbash_txt4>/'"${dcol_txt1}"'/g
                s/<wallbash_4xa1>/'"${dcol_1xa9}"'/g
                s/<wallbash_4xa2>/'"${dcol_1xa8}"'/g
                s/<wallbash_4xa3>/'"${dcol_1xa7}"'/g
                s/<wallbash_4xa4>/'"${dcol_1xa6}"'/g
                s/<wallbash_4xa5>/'"${dcol_1xa5}"'/g
                s/<wallbash_4xa6>/'"${dcol_1xa4}"'/g
                s/<wallbash_4xa7>/'"${dcol_1xa3}"'/g
                s/<wallbash_4xa8>/'"${dcol_1xa2}"'/g
                s/<wallbash_4xa9>/'"${dcol_1xa1}"'/g
                s/<wallbash_pry1_rgba(\([^)]*\))>/'"${dcol_pry4_rgba}"'/g
                s/<wallbash_txt1_rgba(\([^)]*\))>/'"${dcol_txt4_rgba}"'/g
                s/<wallbash_1xa1_rgba(\([^)]*\))>/'"${dcol_4xa9_rgba}"'/g
                s/<wallbash_1xa2_rgba(\([^)]*\))>/'"${dcol_4xa8_rgba}"'/g
                s/<wallbash_1xa3_rgba(\([^)]*\))>/'"${dcol_4xa7_rgba}"'/g
                s/<wallbash_1xa4_rgba(\([^)]*\))>/'"${dcol_4xa6_rgba}"'/g
                s/<wallbash_1xa5_rgba(\([^)]*\))>/'"${dcol_4xa5_rgba}"'/g
                s/<wallbash_1xa6_rgba(\([^)]*\))>/'"${dcol_4xa4_rgba}"'/g
                s/<wallbash_1xa7_rgba(\([^)]*\))>/'"${dcol_4xa3_rgba}"'/g
                s/<wallbash_1xa8_rgba(\([^)]*\))>/'"${dcol_4xa2_rgba}"'/g
                s/<wallbash_1xa9_rgba(\([^)]*\))>/'"${dcol_4xa1_rgba}"'/g
                s/<wallbash_pry2_rgba(\([^)]*\))>/'"${dcol_pry3_rgba}"'/g
                s/<wallbash_txt2_rgba(\([^)]*\))>/'"${dcol_txt3_rgba}"'/g
                s/<wallbash_2xa1_rgba(\([^)]*\))>/'"${dcol_3xa9_rgba}"'/g
                s/<wallbash_2xa2_rgba(\([^)]*\))>/'"${dcol_3xa8_rgba}"'/g
                s/<wallbash_2xa3_rgba(\([^)]*\))>/'"${dcol_3xa7_rgba}"'/g
                s/<wallbash_2xa4_rgba(\([^)]*\))>/'"${dcol_3xa6_rgba}"'/g
                s/<wallbash_2xa5_rgba(\([^)]*\))>/'"${dcol_3xa5_rgba}"'/g
                s/<wallbash_2xa6_rgba(\([^)]*\))>/'"${dcol_3xa4_rgba}"'/g
                s/<wallbash_2xa7_rgba(\([^)]*\))>/'"${dcol_3xa3_rgba}"'/g
                s/<wallbash_2xa8_rgba(\([^)]*\))>/'"${dcol_3xa2_rgba}"'/g
                s/<wallbash_2xa9_rgba(\([^)]*\))>/'"${dcol_3xa1_rgba}"'/g
                s/<wallbash_pry3_rgba(\([^)]*\))>/'"${dcol_pry2_rgba}"'/g
                s/<wallbash_txt3_rgba(\([^)]*\))>/'"${dcol_txt2_rgba}"'/g
                s/<wallbash_3xa1_rgba(\([^)]*\))>/'"${dcol_2xa9_rgba}"'/g
                s/<wallbash_3xa2_rgba(\([^)]*\))>/'"${dcol_2xa8_rgba}"'/g
                s/<wallbash_3xa3_rgba(\([^)]*\))>/'"${dcol_2xa7_rgba}"'/g
                s/<wallbash_3xa4_rgba(\([^)]*\))>/'"${dcol_2xa6_rgba}"'/g
                s/<wallbash_3xa5_rgba(\([^)]*\))>/'"${dcol_2xa5_rgba}"'/g
                s/<wallbash_3xa6_rgba(\([^)]*\))>/'"${dcol_2xa4_rgba}"'/g
                s/<wallbash_3xa7_rgba(\([^)]*\))>/'"${dcol_2xa3_rgba}"'/g
                s/<wallbash_3xa8_rgba(\([^)]*\))>/'"${dcol_2xa2_rgba}"'/g
                s/<wallbash_3xa9_rgba(\([^)]*\))>/'"${dcol_2xa1_rgba}"'/g
                s/<wallbash_pry4_rgba(\([^)]*\))>/'"${dcol_pry1_rgba}"'/g
                s/<wallbash_txt4_rgba(\([^)]*\))>/'"${dcol_txt1_rgba}"'/g
                s/<wallbash_4xa1_rgba(\([^)]*\))>/'"${dcol_1xa9_rgba}"'/g
                s/<wallbash_4xa2_rgba(\([^)]*\))>/'"${dcol_1xa8_rgba}"'/g
                s/<wallbash_4xa3_rgba(\([^)]*\))>/'"${dcol_1xa7_rgba}"'/g
                s/<wallbash_4xa4_rgba(\([^)]*\))>/'"${dcol_1xa6_rgba}"'/g
                s/<wallbash_4xa5_rgba(\([^)]*\))>/'"${dcol_1xa5_rgba}"'/g
                s/<wallbash_4xa6_rgba(\([^)]*\))>/'"${dcol_1xa4_rgba}"'/g
                s/<wallbash_4xa7_rgba(\([^)]*\))>/'"${dcol_1xa3_rgba}"'/g
                s/<wallbash_4xa8_rgba(\([^)]*\))>/'"${dcol_1xa2_rgba}"'/g
                s/<wallbash_4xa9_rgba(\([^)]*\))>/'"${dcol_1xa1_rgba}"'/g' "${target}"
    else
        sed -i 's/<wallbash_mode>/'"${dcol_mode}"'/g
                s/<wallbash_pry1>/'"${dcol_pry1}"'/g
                s/<wallbash_txt1>/'"${dcol_txt1}"'/g
                s/<wallbash_1xa1>/'"${dcol_1xa1}"'/g
                s/<wallbash_1xa2>/'"${dcol_1xa2}"'/g
                s/<wallbash_1xa3>/'"${dcol_1xa3}"'/g
                s/<wallbash_1xa4>/'"${dcol_1xa4}"'/g
                s/<wallbash_1xa5>/'"${dcol_1xa5}"'/g
                s/<wallbash_1xa6>/'"${dcol_1xa6}"'/g
                s/<wallbash_1xa7>/'"${dcol_1xa7}"'/g
                s/<wallbash_1xa8>/'"${dcol_1xa8}"'/g
                s/<wallbash_1xa9>/'"${dcol_1xa9}"'/g
                s/<wallbash_pry2>/'"${dcol_pry2}"'/g
                s/<wallbash_txt2>/'"${dcol_txt2}"'/g
                s/<wallbash_2xa1>/'"${dcol_2xa1}"'/g
                s/<wallbash_2xa2>/'"${dcol_2xa2}"'/g
                s/<wallbash_2xa3>/'"${dcol_2xa3}"'/g
                s/<wallbash_2xa4>/'"${dcol_2xa4}"'/g
                s/<wallbash_2xa5>/'"${dcol_2xa5}"'/g
                s/<wallbash_2xa6>/'"${dcol_2xa6}"'/g
                s/<wallbash_2xa7>/'"${dcol_2xa7}"'/g
                s/<wallbash_2xa8>/'"${dcol_2xa8}"'/g
                s/<wallbash_2xa9>/'"${dcol_2xa9}"'/g
                s/<wallbash_pry3>/'"${dcol_pry3}"'/g
                s/<wallbash_txt3>/'"${dcol_txt3}"'/g
                s/<wallbash_3xa1>/'"${dcol_3xa1}"'/g
                s/<wallbash_3xa2>/'"${dcol_3xa2}"'/g
                s/<wallbash_3xa3>/'"${dcol_3xa3}"'/g
                s/<wallbash_3xa4>/'"${dcol_3xa4}"'/g
                s/<wallbash_3xa5>/'"${dcol_3xa5}"'/g
                s/<wallbash_3xa6>/'"${dcol_3xa6}"'/g
                s/<wallbash_3xa7>/'"${dcol_3xa7}"'/g
                s/<wallbash_3xa8>/'"${dcol_3xa8}"'/g
                s/<wallbash_3xa9>/'"${dcol_3xa9}"'/g
                s/<wallbash_pry4>/'"${dcol_pry4}"'/g
                s/<wallbash_txt4>/'"${dcol_txt4}"'/g
                s/<wallbash_4xa1>/'"${dcol_4xa1}"'/g
                s/<wallbash_4xa2>/'"${dcol_4xa2}"'/g
                s/<wallbash_4xa3>/'"${dcol_4xa3}"'/g
                s/<wallbash_4xa4>/'"${dcol_4xa4}"'/g
                s/<wallbash_4xa5>/'"${dcol_4xa5}"'/g
                s/<wallbash_4xa6>/'"${dcol_4xa6}"'/g
                s/<wallbash_4xa7>/'"${dcol_4xa7}"'/g
                s/<wallbash_4xa8>/'"${dcol_4xa8}"'/g
                s/<wallbash_4xa9>/'"${dcol_4xa9}"'/g
                s/<wallbash_pry1_rgba(\([^)]*\))>/'"${dcol_pry1_rgba}"'/g
                s/<wallbash_txt1_rgba(\([^)]*\))>/'"${dcol_txt1_rgba}"'/g
                s/<wallbash_1xa1_rgba(\([^)]*\))>/'"${dcol_1xa1_rgba}"'/g
                s/<wallbash_1xa2_rgba(\([^)]*\))>/'"${dcol_1xa2_rgba}"'/g
                s/<wallbash_1xa3_rgba(\([^)]*\))>/'"${dcol_1xa3_rgba}"'/g
                s/<wallbash_1xa4_rgba(\([^)]*\))>/'"${dcol_1xa4_rgba}"'/g
                s/<wallbash_1xa5_rgba(\([^)]*\))>/'"${dcol_1xa5_rgba}"'/g
                s/<wallbash_1xa6_rgba(\([^)]*\))>/'"${dcol_1xa6_rgba}"'/g
                s/<wallbash_1xa7_rgba(\([^)]*\))>/'"${dcol_1xa7_rgba}"'/g
                s/<wallbash_1xa8_rgba(\([^)]*\))>/'"${dcol_1xa8_rgba}"'/g
                s/<wallbash_1xa9_rgba(\([^)]*\))>/'"${dcol_1xa9_rgba}"'/g
                s/<wallbash_pry2_rgba(\([^)]*\))>/'"${dcol_pry2_rgba}"'/g
                s/<wallbash_txt2_rgba(\([^)]*\))>/'"${dcol_txt2_rgba}"'/g
                s/<wallbash_2xa1_rgba(\([^)]*\))>/'"${dcol_2xa1_rgba}"'/g
                s/<wallbash_2xa2_rgba(\([^)]*\))>/'"${dcol_2xa2_rgba}"'/g
                s/<wallbash_2xa3_rgba(\([^)]*\))>/'"${dcol_2xa3_rgba}"'/g
                s/<wallbash_2xa4_rgba(\([^)]*\))>/'"${dcol_2xa4_rgba}"'/g
                s/<wallbash_2xa5_rgba(\([^)]*\))>/'"${dcol_2xa5_rgba}"'/g
                s/<wallbash_2xa6_rgba(\([^)]*\))>/'"${dcol_2xa6_rgba}"'/g
                s/<wallbash_2xa7_rgba(\([^)]*\))>/'"${dcol_2xa7_rgba}"'/g
                s/<wallbash_2xa8_rgba(\([^)]*\))>/'"${dcol_2xa8_rgba}"'/g
                s/<wallbash_2xa9_rgba(\([^)]*\))>/'"${dcol_2xa9_rgba}"'/g
                s/<wallbash_pry3_rgba(\([^)]*\))>/'"${dcol_pry3_rgba}"'/g
                s/<wallbash_txt3_rgba(\([^)]*\))>/'"${dcol_txt3_rgba}"'/g
                s/<wallbash_3xa1_rgba(\([^)]*\))>/'"${dcol_3xa1_rgba}"'/g
                s/<wallbash_3xa2_rgba(\([^)]*\))>/'"${dcol_3xa2_rgba}"'/g
                s/<wallbash_3xa3_rgba(\([^)]*\))>/'"${dcol_3xa3_rgba}"'/g
                s/<wallbash_3xa4_rgba(\([^)]*\))>/'"${dcol_3xa4_rgba}"'/g
                s/<wallbash_3xa5_rgba(\([^)]*\))>/'"${dcol_3xa5_rgba}"'/g
                s/<wallbash_3xa6_rgba(\([^)]*\))>/'"${dcol_3xa6_rgba}"'/g
                s/<wallbash_3xa7_rgba(\([^)]*\))>/'"${dcol_3xa7_rgba}"'/g
                s/<wallbash_3xa8_rgba(\([^)]*\))>/'"${dcol_3xa8_rgba}"'/g
                s/<wallbash_3xa9_rgba(\([^)]*\))>/'"${dcol_3xa9_rgba}"'/g
                s/<wallbash_pry4_rgba(\([^)]*\))>/'"${dcol_pry4_rgba}"'/g
                s/<wallbash_txt4_rgba(\([^)]*\))>/'"${dcol_txt4_rgba}"'/g
                s/<wallbash_4xa1_rgba(\([^)]*\))>/'"${dcol_4xa1_rgba}"'/g
                s/<wallbash_4xa2_rgba(\([^)]*\))>/'"${dcol_4xa2_rgba}"'/g
                s/<wallbash_4xa3_rgba(\([^)]*\))>/'"${dcol_4xa3_rgba}"'/g
                s/<wallbash_4xa4_rgba(\([^)]*\))>/'"${dcol_4xa4_rgba}"'/g
                s/<wallbash_4xa5_rgba(\([^)]*\))>/'"${dcol_4xa5_rgba}"'/g
                s/<wallbash_4xa6_rgba(\([^)]*\))>/'"${dcol_4xa6_rgba}"'/g
                s/<wallbash_4xa7_rgba(\([^)]*\))>/'"${dcol_4xa7_rgba}"'/g
                s/<wallbash_4xa8_rgba(\([^)]*\))>/'"${dcol_4xa8_rgba}"'/g
                s/<wallbash_4xa9_rgba(\([^)]*\))>/'"${dcol_4xa9_rgba}"'/g' "${target}"
    fi

    [ -z "${appexe}" ] || bash -c "${appexe}"
}

export -f fn_wallbash print_log pkg_installed

# Handles the wallbash directories
for dir in "${walbashDirs[@]}"; do
    [ -d "${dir}" ] || walbashDirs=("${walbashDirs[@]//$dir/}")
done

if [ -n "${dcol_colors}" ]; then
    set -a
    # shellcheck disable=SC1090
    source "${dcol_colors}"
    print_log -sec "wallbash" -stat "single instance" "Wallbash Colors: ${dcol_colors}"
    set +a
fi

# Single template mode
if [ -n "${single_template}" ];then
fn_wallbash "${single_template}"
exit 0
fi

# Run when hyprland is running
[ -n "$HYPRLAND_INSTANCE_SIGNATURE" ] && hyprctl keyword misc:disable_autoreload 1 -q && trap 'print_log -sec "[wallbash]" -stat "reload"  "Hyprland" && hyprctl reload -q' EXIT

# Print to terminal the colors
[ -t 1 ] && wallbash.print.colors.sh

#// switch theme <//> wall based colors

# shellcheck disable=SC2154
if [ "${enableWallDcol}" -eq 0 ] && [[ "${reload_flag}" -eq 1 ]]; then

    print_log -sec "wallbash" -stat "apply ${dcol_mode} colors" "${hydeTheme} theme"
    mapfile -d '' -t deployList < <(find "${hydeThemeDir}" -type f -name "*.theme" -print0)

    while read -r pKey; do
        fKey="$(find "${hydeThemeDir}" -type f -name "$(basename "${pKey%.dcol}.theme")")"
        [ -z "${fKey}" ] && deployList+=("${pKey}")
    done < <(find "${walbashDirs[@]}" -type f -path "*/theme*" -name "*.dcol" 2>/dev/null | awk '!seen[substr($0, match($0, /[^/]+$/))]++')

    parallel fn_wallbash ::: "${deployList[@]}"

elif [ "${enableWallDcol}" -gt 0 ]; then
    print_log -sec "wallbash" -stat "apply ${dcol_mode} colors" "Wallbash theme"
    # This is the reason we avoid SPACES for the wallbash template names
    find "${walbashDirs[@]}" -type f -path "*/theme*" -name "*.dcol" 2>/dev/null | awk '!seen[substr($0, match($0, /[^/]+$/))]++' | parallel fn_wallbash {}
fi

#  Theme mode: detects the color-scheme set in hypr.theme and falls back if nothing is parsed.
revert_colors=0
[ "${enableWallDcol}" -eq 0 ] && grep -q "${dcol_mode}" <<<"$(get_hyprConf "COLOR_SCHEME")" || revert_colors=1
export revert_colors

find "${walbashDirs[@]}" -type f -path "*/always*" -name "*.dcol" 2>/dev/null | sort | awk '!seen[substr($0, match($0, /[^/]+$/))]++' | parallel fn_wallbash {}

#? Post deployment

# Validate the theme configuration file
cat <<WALLBASH >"${confDir}/hypr/themes/wallbash.conf"
# Auto-generated by HyDE // Read-only
# // ----------------------------
# HyDE Theme: ${hydeTheme}
# Configuration File: "${hydeThemeDir}/hypr.theme"
# Wallbash Mode : $(sed -e 's/^0$/theme/' -e 's/^1$/auto/' -e 's/^2$/dark/' -e 's/^3$/light/' <<<"${enableWallDcol}")
# // ----------------------------

\$HYDE_THEME=${hydeTheme}
\$GTK_THEME=$(get_hyprConf 'GTK_THEME')
\$ICON_THEME=$(get_hyprConf 'ICON_THEME')
\$COLOR-SCHEME=$(get_hyprConf 'COLOR_SCHEME')

\$CURSOR_THEME=$(get_hyprConf 'CURSOR_THEME')
\$CURSOR_SIZE=$(get_hyprConf 'CURSOR_SIZE')

\$FONT=$(get_hyprConf 'FONT')
\$FONT_SIZE=$(get_hyprConf 'FONT_SIZE')
\$DOCUMENT_FONT=$(get_hyprConf 'DOCUMENT_FONT')
\$DOCUMENT_FONT_SIZE=$(get_hyprConf 'DOCUMENT_FONT_SIZE')
\$MONOSPACE_FONT=$(get_hyprConf 'MONOSPACE_FONT')
\$MONOSPACE_FONT_SIZE=$(get_hyprConf 'MONOSPACE_FONT_SIZE')


\$CODE_THEME=$(get_hyprConf 'CODE_THEME')
\$SDDM_THEME=$(get_hyprConf 'SDDM_THEME')

# // ----------------------------
# README:
# Values above are derived and sanitized from the Configuration File,
# This is to ensure themes won't have any 'exec' or 'source'
# commands that could potentially harm the system
#  or undesired behavior.
#
# Dear Theme Owner:
# You can still add your own custom 'exec' or 'source' commands
#  by adding it as variable, examples (you can name the variable anything):
# Note that you should indicate it in your README.md
#
#
# -- ⌨️ theme.conf --
# \$RUN_CMD="some_command"
# \$SOURCE_FILE="/some/files"
#
#
# -- ⌨️ hyprland.conf --
# exec = \${RUN_CMD}"
# source = \${SOURCE_FILE}
# exec = Hyde code theme \$CODE_THEME # Setting the code theme

# // ----------------------------
WALLBASH

#// cleanup
# Define an array of patterns to remove
# Supports regex patterns
deleteRegex=(
    "^ *exec"
    "^ *decoration[^:]*: *drop_shadow"
    "^ *drop_shadow"
    "^ *decoration[^:]*: *shadow *="
    "^ *decoration[^:]*: *col.shadow* *="
    "^ *shadow_"
    "^ *col.shadow*"
)

deleteRegex+=("${hypr_sanitize[@]}")

# Loop through each pattern and remove matching lines
for pattern in "${deleteRegex[@]}"; do
    grep -E "${pattern}" "${confDir}/hypr/themes/theme.conf" | while read -r line; do
        sed -i "\|${line}|d" "${confDir}/hypr/themes/theme.conf"
        print_log -sec "theme" -warn "sanitize" "${line}"
    done
done
