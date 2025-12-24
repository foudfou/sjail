#!/bin/sh
basedir=$(dirname $(realpath "$0"))

. $basedir/pre.sh

cleanup() {
    rm sjail-test.* ||true
    ssh root@"${vm1}" jail -r j01 ||true
    ssh root@"${vm1}" sjail destroy j01 ||true
    tap_fail "unexpected error... cleaned up"
    exit 1
}

t="networking shared interface"

setup() {
    out1=$(mktemp sjail-test.XXXXXX)
    out2=$(mktemp sjail-test.XXXXXX)

    install_sjail "${vm1}" "${CONF_DEFAULT}" "${PF_DEFAULT}"
    ssh root@"${vm2}" "service pf stop" ||true
}
setup

new_jail ${vm1} j01 ip4=${jail1}/24
conn_vm_jail_ok "vm2 → j01" ${vm1} j01 ${jail1} ${vm2}
delete_jail ${vm1} j01

tap_end
