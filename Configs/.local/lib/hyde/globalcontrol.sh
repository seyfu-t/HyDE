#!/usr/bin/env bash

#// hyde envs

export confDir="${XDG_CONFIG_HOME:-$HOME/.config}"
export hydeConfDir="${confDir}/hyde"
export cacheDir="$HOME/.cache/hyde"
export thmbDir="${cacheDir}/thumbs"
export dcolDir="${cacheDir}/dcols"
export iconsDir="${XDG_DATA_HOME}/icons"
export themesDir="${XDG_DATA_HOME}/themes"
export fontsDir="${XDG_DATA_HOME}/themes"
export hashMech="sha1sum"

get_hashmap() {
    unset wallHash
    unset wallList
    unset skipStrays
    unset verboseMap

    validSources=()
    for wallSource in "$@"; do
        [ -z "${wallSource}" ] && continue
        case "${wallSource}" in
        --skipstrays) skipStrays=1 ;;
        --verbose) verboseMap=1 ;;
        *) validSources+=("${wallSource}") ;;
        esac
    done

    if [ ${#validSources[@]} -eq 0 ]; then
        echo "ERROR: No valid image sources provided"
        exit 1
    fi

    # 200ms reduction
    # hashMap=$(find "${validSources[@]}" -type f \( -iname "*.gif" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) -print0 | xargs -0 "${hashMech}" | sort -k2)

    # if [ -z "${hashMap}" ]; then
    #     echo "WARNING: No images found in the provided sources:"
    #     for source in "${validSources[@]}"; do
    #         num_files=$(find "${source}" -type f \( -iname "*.gif" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | wc -l)
    #         echo " x ${source} - ${num_files} files"
    #     done
    #     exit 1
    # fi

    while read -r hash image; do
        wallHash+=("${hash}")
        wallList+=("${image}")
    done <<<"$(find "${validSources[@]}" -type f \( -iname "*.gif" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) -print0 | xargs -0 "${hashMech}" | sort -k2)"

    if [ -z "${#wallList[@]}" ] || [[ "${#wallList[@]}" -eq 0 ]]; then
        if [[ "${skipStrays}" -eq 1 ]]; then
            return 1
        else
            echo "ERROR: No image found in any source"
            exit 1
        fi
    fi

    if [[ "${verboseMap}" -eq 1 ]]; then
        echo "// Hash Map //"
        for indx in "${!wallHash[@]}"; do
            echo ":: \${wallHash[${indx}]}=\"${wallHash[indx]}\" :: \${wallList[${indx}]}=\"${wallList[indx]}\""
        done
    fi
}

# shellcheck disable=SC2120
get_themes() {
    unset thmSortS
    unset thmListS
    unset thmWallS
    unset thmSort
    unset thmList
    unset thmWall

    # TODO slow! 500ms
    while read -r thmDir; do
        local realWallPath
        realWallPath="$(readlink "${thmDir}/wall.set")"
        if [ ! -e "${realWallPath}" ]; then
            get_hashmap "${thmDir}" --skipstrays || continue
            echo "fixing link :: ${thmDir}/wall.set"
            ln -fs "${wallList[0]}" "${thmDir}/wall.set"
        fi
        [ -f "${thmDir}/.sort" ] && thmSortS+=("$(head -1 "${thmDir}/.sort")") || thmSortS+=("0")
        thmWallS+=("${realWallPath}")
        thmListS+=("${thmDir##*/}") # Use this instead of basename
    done < <(find "${hydeConfDir}/themes" -mindepth 1 -maxdepth 1 -type d)

    while IFS='|' read -r sort theme wall; do
        thmSort+=("${sort}")
        thmList+=("${theme}")
        thmWall+=("${wall}")
        # done < <(awk 'BEGIN {FS=OFS="|"} {print $1, $2, $3}' <(printf "%s\n" "${thmSortS[@]}") <(printf "%s\n" "${thmListS[@]}") <(printf "%s\n" "${thmWallS[@]}") | sort -n -k 1 -k 2)
    done < <(paste -d '|' <(printf "%s\n" "${thmSortS[@]}") <(printf "%s\n" "${thmListS[@]}") <(printf "%s\n" "${thmWallS[@]}") | sort -n -k 1 -k 2)
    # done < <(parallel --link echo "{1}\|{2}\|{3}" ::: "${thmSortS[@]}" ::: "${thmListS[@]}" ::: "${thmWallS[@]}" | sort -n -k 1 -k 2)
    # exit 0
    if [ "${1}" == "--verbose" ]; then
        echo "// Theme Control //"
        for indx in "${!thmList[@]}"; do
            echo -e ":: \${thmSort[${indx}]}=\"${thmSort[indx]}\" :: \${thmList[${indx}]}=\"${thmList[indx]}\" :: \${thmWall[${indx}]}=\"${thmWall[indx]}\""
        done
    fi
}

[ -f "${hydeConfDir}/hyde.conf" ] && source "${hydeConfDir}/hyde.conf"

case "${enableWallDcol}" in
0 | 1 | 2 | 3) ;;
*) enableWallDcol=0 ;;
esac

if [ -z "${hydeTheme}" ] || [ ! -d "${hydeConfDir}/themes/${hydeTheme}" ]; then
    get_themes
    hydeTheme="${thmList[0]}"
fi

hydeThemeDir="${hydeConfDir}/themes/${hydeTheme}"
walbashDirs=(
    "${hydeConfDir}/wallbash"
    "${XDG_DATA_HOME}/hyde/wallbash"
    "/usr/local/share/hyde/wallbash"
    "/usr/share/hyde/wallbash"

)

for dir in "${walbashDirs[@]}"; do
    [ -d "${dir}" ] || walbashDirs=("${walbashDirs[@]//$dir/}")
done

echo "${walbashDirs[@]}"

export hydeTheme
export hydeThemeDir
export walbashDirs
export enableWallDcol

#// hypr vars

if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    export hypr_border="$(hyprctl -j getoption decoration:rounding | jq '.int')"
    export hypr_width="$(hyprctl -j getoption general:border_size | jq '.int')"

fi

#// extra fns

pkg_installed() {
    local pkgIn=$1
    if pacman -Qi "${pkgIn}" &>/dev/null; then
        return 0
    elif pacman -Qi "flatpak" &>/dev/null && flatpak info "${pkgIn}" &>/dev/null; then
        return 0
    elif command -v "${pkgIn}" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

get_aurhlpr() {
    if pkg_installed yay; then
        aurhlpr="yay"
    elif pkg_installed paru; then
        aurhlpr="paru"
    fi
}

set_conf() {
    local varName="${1}"
    local varData="${2}"
    touch "${hydeConfDir}/hyde.conf"

    if [ $(grep -c "^${varName}=" "${hydeConfDir}/hyde.conf") -eq 1 ]; then
        sed -i "/^${varName}=/c${varName}=\"${varData}\"" "${hydeConfDir}/hyde.conf"
    else
        echo "${varName}=\"${varData}\"" >>"${hydeConfDir}/hyde.conf"
    fi
}

set_hash() {
    local hashImage="${1}"
    "${hashMech}" "${hashImage}" | awk '{print $1}'
}
