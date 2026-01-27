#!/bin/sh

HLINE="────"

JAIL_CONF_DELIM='`'

log_fatal() {
    >&2 echo "Error: $1"
    exit 1
}

log() {
    echo "$*"
}

log_debug() {
    :
}

sysrc_silent() {
    sysrc "$1" >/dev/null
}

prop_get() {
    grep -m1 -E "^\s*${1}\s*=" "${2}" | cut -d'=' -f2
}

arg_get() {
    local opt=$1; shift
    echo "$@" | awk 'BEGIN{RS=" ";FS="="} /^'${opt}'=/ {print $2}'
}

# Note a function can return 2 arguments, but they have to be read with:
# read k v <<EOF
# $(jail_conf_get j01 sysvshm)
# EOF

# It's important to understand that:
#
# 1. jail -e is for *all* jails; i.e. can't be applied to a single jail;
#
# 2. the output of jail -e ends with a newline; in order to avoid awk include
#    that newline in the last record, we transform that newline beforehand.
#
# 3. the jail.conf format spec is really hairy. It's thus more convenient to
#    have a dedicated function per type.
jail_conf() {
    local jail=$1
    jail -e "${JAIL_CONF_DELIM}" | grep -E '^name='"${jail}""${JAIL_CONF_DELIM}"
}

jail_conf_get_bool() {
    local param=$1
    read conf
    echo -n "${conf}" | tr '\n' "${JAIL_CONF_DELIM}" \
        | awk 'BEGIN{RS="'"${JAIL_CONF_DELIM}"'";FS="="} /^'"${param}"'$/ {print $1}'
}

jail_conf_get_val() {
    local param=$1
    read conf
    echo -n "${conf}" | tr '\n' "${JAIL_CONF_DELIM}" \
        | awk 'BEGIN{RS="'"${JAIL_CONF_DELIM}"'";FS="="} /^'"${param}"'=/ {print $2}'
}

jail_conf_get_ips() {
    local class=$1; shift
    local jail_name=$1; shift

    local ips=""

    local addr=$(jail_conf "${jail_name}" | jail_conf_get_val "${class}.addr" | sed 's/,/ /g')
    local ip
    for ip in ${addr}; do
        ip=${ip##*|}
        ip=${ip%%/*}
        ips="${ips} ${ip}"
    done

    echo "${ips# }"
}

jail_get_ips() {
    local class=$1; shift
    local jail_name=$1; shift
    local rc_conf=$1; shift

    local ips=$(jail_conf_get_ips "${class}" "${jail_name}")
    if [ -z "${ips}" ]; then
        ips=$(jail_vnet_get_ip "${class}" "${jail_name}" "${rc_conf}")
    fi

    echo "$ips"
}

# Until we encounter use cases for multi-IPs, only a single ip4 or ip6 is
# supported. This is ineed inconsistent with jail_conf_get_ips. We should have
# avoided multi-IPs for the same reason.
jail_vnet_get_ip() {
    local class=$1; shift
    local jail_name=$1; shift
    local rc_conf=$1; shift

    local ip=""
    local epair_name="e0b_$(sh_var ${jail_name})"
    if [ "${class}" = ip4 ]; then
        ip=$(sysrc -f "${rc_conf}" -ni ifconfig_${epair_name})
        ip=${ip##inet }
        ip=${ip%% inet*} # single ip
        ip=${ip%%/*}
    elif [ "${class}" = ip6 ]; then
        ip=$(sysrc -f "${rc_conf}" -ni ifconfig_${epair_name}_ipv6)
        ip=${ip##inet6 }
        ip=${ip%% inet6*} # single ip
        ip=${ip%% prefixlen*}
        ip=${ip%%/*}
    fi

    echo "${ip}"
}

# rc.conf keys are shell variable but jail (host)names may contain other chars.
sh_var() {
    echo "$1" | tr '-' '_'
}

# Deterministic MACs to avoid ARP cache instability.
jail_macs() {
    local name="$1"

    local h=$(printf "%s" "$name" | md5)
    local bytes=$(printf "%.12s" "$h" | sed 's/../& /g')
    printf "02:ff:ff:%s:%s:%s 02:ff:ff:%s:%s:%s" $bytes
}

get_version_components() {
    local version=$1  # 15.0-RELEASE

    local major=${version%%.*}
    local rest=${version##*.}
    local minor=${rest%%-*}
    local branch=${rest##*-}

    printf '%s %s %s\n' "$major" "$minor" "$branch"
}

make_pkg_cmd() {
    local release_path=$1
    local version=$2

    read VERSION_MAJOR VERSION_MINOR BRANCH <<EOF
$(get_version_components ${version})
EOF

    local repos_dir="${release_path}/.pkgrepos"
    local fingerprints="${release_path}/usr/share/keys/pkgbase-${VERSION_MAJOR}"
    local ABI="FreeBSD:${VERSION_MAJOR}:amd64"
    printf "pkg --rootdir ${release_path} --repo-conf-dir ${repos_dir} \
-o IGNORE_OSVERSION=yes \
-o VERSION_MAJOR=${VERSION_MAJOR} \
-o VERSION_MINOR=${VERSION_MINOR} \
-o ABI=${ABI} \
-o ASSUME_ALWAYS_YES=yes \
-o FINGERPRINTS=${fingerprints}\n"
}
