#!/usr/bin/env bash

# Copied from https://github.com/davatorium/rofi/blob/next/script/rofi-theme-selector

if [ $# -ne 1 ]
then
    echo "Usage: $0 <theme>"
    exit 1
fi

THEME=$1

OS="gnu"
case "$OSTYPE" in
    *linux*|*hurd*|*msys*|*cygwin*|*sua*|*interix*) OS="gnu";;
    *bsd*|*darwin*) OS="bsd";;
    *sunos*|*solaris*|*indiana*|*illumos*|*smartos*) OS="sun";;
esac

ROFI=$(command -v rofi)
if [ $OS = "bsd" ]; then
    SED=$(command -v gsed)
else
    SED=$(command -v sed)
fi
MKTEMP=$(command -v mktemp)

if [ -z "${SED}" ]
then
    echo "Did not find 'sed', script cannot continue."
    exit 1
fi
if [ -z "${MKTEMP}" ]
then
    echo "Did not find 'mktemp', script cannot continue."
    exit 1
fi
if [ -z "${ROFI}" ]
then
    echo "Did not find rofi, there is no point to continue."
    exit 1
fi

TMP_CONFIG_FILE=$(${MKTEMP}).rasi

##
# Create a copy of rofi
##
create_config_copy()
{
    ${ROFI} -dump-config > "${TMP_CONFIG_FILE}"
    # remove theme entry.
    ${SED} -i 's/^\s*theme:\s\+".*"\s*;//g' "${TMP_CONFIG_FILE}"
}

###
# Create if not exists, then removes #include of .theme file (if present) and add the selected theme to the end.
# Repeated calls should leave the config clean-ish
###
set_theme()
{
    CDIR="${XDG_CONFIG_HOME:-${HOME}/.config}/rofi"
    if [ ! -d "${CDIR}" ]
    then
        mkdir -p "${CDIR}"
    fi
    # on BSD & MacOS readlink acts differently
    if [ $OS = "bsd" ]; then
        get_link="$(realpath "${CDIR}")/config.rasi"
    else
        get_link=$(readlink -f "${CDIR}/config.rasi")
    fi
    if [[ ! -f "${get_link}" ]]
    then
       touch "${get_link}"
    fi

    # Comment old base theme, not replace as it may be modified after the line
    ${SED} -i '/^\s*@theme/ s,^,//,' "${get_link}"
    echo -e "\n@theme \"${1}\"" >> "${get_link}"
}

create_config_copy
set_theme "${THEME}"

##
# Remove temp. config.
##
rm -- "${TMP_CONFIG_FILE}"
