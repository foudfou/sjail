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
    local jail_name=$1
    local class=$2

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
