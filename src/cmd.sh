#!/bin/sh
# Commands are used in the context of `sjail apply`: important global
# variables are available and the script runs as root.
#
# We need a running jail to apply recipes, because many operations need it (CMD
# but also PKG, SYSRC or SERVICE), even when run from the host (pkg -j, sysrc
# -j etc.)
set -ue


CMD() {
    # jexec -U root would be redundant.
    jexec -l "${jail_name}" "$@"
}

CONF() {
    local param=$1
    # split string to array
    OIFS="$IFS"
    IFS='='
    set ${1}
    IFS="$OIFS"

    local k="${1}"
    local v=""
    [ $# -gt 1 ] && v="${2}"

    # jail -m does not persist. sysrc -f not compatible with jail.conf. jail -e
    # does variable expansion so we'd loose readability. We thus resort to wild
    # pattern matching in jail.conf for now.
    #
    # TODO support += notation
    if [ -z "${v}" ]; then
        if grep -m1 -qE "${k}\s*;" "${jail_path}/jail.conf"; then
            :  # already set
        else
            sed -i '' 's|}|  '${k}';\'$'\n''}|' "${jail_path}/jail.conf"
        fi
    elif grep -m1 -qE "${k}\s*=\s*${v}" "${jail_path}/jail.conf"; then
        sed -i '' "s|${k} = .*;|${k} = ${v};|" "${jail_path}/jail.conf"
    else  # append
        sed -i '' 's|}|  '${k}' = '${v}';\'$'\n''}|' "${jail_path}/jail.conf"
    fi

    # restarts the jails if needed
    jail -mr "name=${jail_name}" "${param}"
}

CP() {
    return
}

INCLUDE() {
    local recipe=$1; shift

    while [ $# -gt 0 ]; do
        local arg=$1; shift
        if echo "$arg" | grep -q -E '[^= \t]+=[^= \t]+'; then
            eval "local $arg"
        else
            log_fatal "argument invalid format: ${arg}"
        fi
    done

    . "${zfs_mount}/recipes/${recipe}/install.sh"
}

# No checks! Safety not guaranteed.
MOUNT() {
    local src=$1; shift
    local dst=$1; shift
    local opts="$@"

    dst="${zfs_mount}/jails/${jail_name}/root/${dst}"
    [ -d "${dst}" ] || mkdir -p "${dst}"

    local line="${src} ${dst} ${opts}"
    local fstab="${zfs_mount}/jails/${jail_name}/fstab"
    if ! grep -qE "${line}" "${fstab}"; then
        echo "$line" >> "${fstab}"
    fi

    # mount immediately otherwise jail -r will complain that dst is not mounted
    mount -F "${fstab}" -a
}

PKG() {
    # Not using host: pkg -j "${jail_name}" install -y "$@"
    jexec -l "${jail_name}" pkg install -y "$@"
}

EXPOSE() {
    local proto=$1 host_port=$2 jail_port=$3
    echo "${proto} ${host_port} ${jail_port}" >> "${jail_path}/rdr.conf"
}

SERVICE() {
    jexec -l "${jail_name}" service "$@"
}

SYSRC() {
    # Not using host: sysrc -j "${jail_name}" "$@"
    jexec -l -U root "${jail_name}" sysrc "$@"
}
