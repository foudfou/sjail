#!/bin/sh

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
    echo "$@" | awk 'BEGIN{RS=" ";FS="="} /'${opt}'/ {print $2}'
}

output_get_word() {
    echo -e "$1" | grep -w "$2" || true
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
jail_conf_get_bool() {
    local jail=$1 param=$2
    jail -e '|' | grep -E '^name='"${jail}"'\|' | tr '\n' '|' \
        | awk 'BEGIN{RS="|";FS="="} /^'"${param}"'$/ {print $1}'
}

jail_conf_get_val() {
    local jail=$1 param=$2
    jail -e '|' | grep -E '^name='"${jail}"'\|' | tr '\n' '|' \
        | awk 'BEGIN{RS="|";FS="="} /^'"${param}"'=/ {print $2}'
}
