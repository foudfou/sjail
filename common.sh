#!/bin/sh

log_fatal() {
    echo "Error: $1" 1>&2
    exit 1
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

jail_conf_get() {
    jail -e'|' | grep "name=$1|" | awk 'BEGIN{RS="|";FS="="} /'"$2"'/ {print $2}'
}
