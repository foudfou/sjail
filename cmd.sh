#!/bin/sh
set -ue
base_dir=$(dirname $(realpath $0))


pf_rdr_add() {
    local jail_name=$1 proto=$2 host_port=$3 jail_port=$4

    local ext_if=$(prop_get ${pf_ext_if} /etc/pf.conf)

    local jail_ip4=$(jail_conf_get "${jail_name}" ip4.addr)
    if [ -n "$jail_ip4" ]; then
        ( pfctl -a "rdr/${jail_name}" -Psn 2> /dev/null; # previous
          echo "rdr pass on ${ext_if} inet proto ${proto}" \
               "to port ${host_port} -> ${jail_ip4} port ${jail_port}" ) \
            | pfctl -a "rdr/${jail_name}" -f-
    fi

    local jail_ip6=$(jail_conf_get "${jail_name}" ip6.addr)
    if [ -n "$jail_ip6" ]; then
        ( pfctl -a "rdr/${jail_name}" -Psn 2> /dev/null; # previous
          echo "rdr pass on ${ext_if} inet6 proto ${proto}" \
               "to port ${host_port} -> ${jail_ip6} port ${jail_port}" ) \
            | pfctl -a "rdr/${jail_name}" -f-
    fi
}

pf_rdr_clear() {
    local jail_name=$1
    pfctl -a "rdr/${jail_name}" -Fn
}


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
    local tpl=$1; shift

    while [ $# -gt 0 ]; do
        local arg=$1; shift
        if echo "$arg" | grep -q -E '[^= \t]+=[^= \t]+'; then
            eval "local $arg"
        else
            log_fatal "argument invalid format: ${arg}"
        fi
    done

    . "${zfs_mount}/templates/${tpl}"
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
