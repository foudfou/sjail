#!/bin/sh
set -ue
base_dir=$(dirname $(realpath $0))


CMD() {
    jexec -l -u root "${jail_name}" "$@"
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
    return
}

PKG() {
    return
}

EXPOSE() {
    local proto=$1 host_port=$2 jail_port=$3
    echo "${proto} ${host_port} ${jail_port}" >> "${jail_path}/rdr.conf"
}

SERVICE() {
    return
}

SYSRC() {
    return
}

PKG() {
    return
}
