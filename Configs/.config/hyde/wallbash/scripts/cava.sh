#!/usr/bin/env sh

# Normally, before invoking this script, the following variables should be set:
# pkg_installed - function to check if a package is installed
# confDir - the $XDGC_CONFIG_HOME directory

confDir="${confDir:-$XDG_CONFIG_HOME}"
cacheDir="${cacheDir:-$XDG_CACHE_HOME/hyde}"
cvaDir="${confDir}/cava"
CAVA_CONF="${cvaDir}/config"
CAVA_DCOL="${cacheDir}/wallbash/cava"
KEY_LINE='### Auto generated wallbash colors ###'

if pkg_installed cava ; then

    sed -i "/${KEY_LINE}/,\$d" "${CAVA_CONF}"
    if grep -q "${KEY_LINE}" "${CAVA_CONF}"; then
        sed -i "/${KEY_LINE}/r ${CAVA_DCOL}" "${CAVA_CONF}"
    else
        echo "${KEY_LINE}" >> "${CAVA_CONF}"
        sed -i "/${KEY_LINE}/r ${CAVA_DCOL}" "${CAVA_CONF}"
    fi

    pkill -USR2 cava

fi
