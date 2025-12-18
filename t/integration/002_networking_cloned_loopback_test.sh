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

pf='ext_if=vtnet0
icmp_types  = "{ echoreq, unreach }"
icmp6_types = "{ echoreq, unreach, routeradv, neighbrsol, neighbradv }"

# sjail-managed
table <jails> persist

set skip on lo

# sjail-managed
rdr-anchor "rdr/*"

nat on $ext_if from <jails> to any -> ($ext_if:0)

block in all
pass out all keep state
antispoof for $ext_if

pass inet proto icmp icmp-type $icmp_types
pass inet6 proto icmp6 icmp6-type $icmp6_types

# Allow ssh
pass in inet proto tcp from any to any port ssh flags S/SA keep state'

for vm in $vm1 $vm2; do
    install_sjail "${vm}" "${conf}" "${pf}"

    ssh root@"${vm}" 'sysrc cloned_interfaces+="lo1" && service netif cloneup'
done


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
