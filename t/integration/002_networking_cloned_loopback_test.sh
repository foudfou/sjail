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

t="networking cloned loopback"

conf='zfs_dataset="zroot/sjail"
zfs_mount="/sjail"
interface="lo1"
ext_if="vtnet0"'

setup() {
    install_sjail "${vm1}" "${conf}" "${PF_DEFAULT}"
    ssh root@${vm1} 'sysrc cloned_interfaces+="lo1" && service netif cloneup'
}
setup


ssh root@"${vm1}" sjail create j01 "${release}" ip4="${jail1_lo}"/24 nat=1 rdr=1
echo "tcp 1234 5555" | ssh root@"${vm1}" -T "cat > /sjail/jails/j01/rdr.conf"
ssh root@"${vm1}" jail -c j01


out1=$(mktemp sjail-test.XXXXXX)
ssh root@"${vm1}" "timeout 3 jexec -l j01 nc -v -l 5555" >$out1 2>&1 &
pid=$!
sleep .5
out2=$(mktemp sjail-test.XXXXXX)
ssh root@"${vm2}" nc -v -w 2 -z "${vm1}" 1234 >$out2 2>&1
wait $pid

grep -q "Connection from ${vm2} .* received!" $out1
tap_ok $? "$t: connection received"
grep -q "Connection to ${vm1} 1234 port \[tcp/\*\] succeeded!" $out2
tap_ok $? "$t: connection succeded"


rm sjail-test.*
ssh root@"${vm1}" jail -r j01
ssh root@"${vm1}" sjail destroy j01

tap_end
