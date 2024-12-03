#!/bin/sh
set -ue
base_dir=$(dirname $(realpath $0))

# These commands are used in the context of `sjail apply`, where important
# global variables are provided and we run as root.

CMD() {
    # jexec -U root would be redundant.
    jexec -l "${jail_name}" "$@"
}

CONFIG() {
    local param=$1

    local k=${param%%=*}
    local v=${param##*=}

    # jail -m does not persist :(
    #
    # TODO support += notation
    if grep -m1 -E "${k}\s*=\s*${v}" "${jail_path}/jail.conf"; then
        sed -i '' "s|${k} = .*;|${k} = ${v};|" "${jail_path}/jail.conf"
    else  # append
        sed -i '' 's|}|  '${k}' = '${v}';\'$'\n''}|' "${jail_path}/jail.conf"
    fi
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

    . "${zfs_mount}/recipes/${recipe}/Recipe"
}

MOUNT() {
    local in="$*"

    local src=$(echo "$in" | cut -d" " -f1)
    local dst=$(echo "$in" | cut -d" " -f2)
    local opts=$(echo "$in" | cut -d" " -f3-)

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
