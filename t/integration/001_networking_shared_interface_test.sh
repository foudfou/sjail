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

install_sjail() {
    local vm=$1

    file_list="sjail/makefile sjail/src"
    tar cf - -C $basedir/../../.. ${file_list} \
        | ssh root@"${vm}" tar xf -

    ssh root@"${vm}" "cd sjail && make install"

    cat <<EOF | ssh root@"${vm}" -T "cat > /usr/local/etc/sjail.conf"
zfs_dataset="zroot/sjail"
zfs_mount="/sjail"
interface="vtnet0"
pf_ext_if=""
EOF

    cat <<EOF | ssh root@"${vm}" -T "cat > /etc/pf.conf"
ext_if=vtnet0
icmp_types  = "{ echoreq, unreach }"
icmp6_types = "{ echoreq, unreach, routeradv, neighbrsol, neighbradv }"

# sjail-managed
table <jails> persist

set skip on lo

# sjail-managed
rdr-anchor "rdr/*"

nat on \$ext_if from <jails> to any -> (\$ext_if:0)

block in all
pass out all keep state
antispoof for \$ext_if

pass inet proto icmp icmp-type \$icmp_types
pass inet6 proto icmp6 icmp6-type \$icmp6_types

# Allow local network
pass from \$ext_if:network to any keep state

# Allow ssh
pass in inet proto tcp from any to any port ssh flags S/SA keep state
EOF
    ssh root@"${vm}" "service pf reload" ||true

    ssh root@"${vm}" "sjail init" ||true
}

install_sjail "${vm1}"
install_sjail "${vm2}"

ssh root@"${vm1}" sjail create j01 "${release}" ip4="${jail1}"/24
ssh root@"${vm1}" jail -c j01

out1=$(mktemp sjail-test.XXXXXX)
ssh root@"${vm1}" "timeout 3 jexec -l j01 nc -v -l 5555" >$out1 2>&1 &
pid=$!
sleep .5
out2=$(mktemp sjail-test.XXXXXX)
ssh root@"${vm2}" nc -v -z "${jail1}" 5555 >$out2 2>&1
wait $pid

grep -qE "Connection from ${vm2} .* received!" $out1
tap_ok $? "$t: connection received"
grep -qE "Connection to ${jail1} 5555 port \[tcp/personal-agent\] succeeded!" $out2
tap_ok $? "$t: connection succeded"



rm sjail-test.*
ssh root@"${vm1}" jail -r j01
ssh root@"${vm1}" sjail destroy j01

tap_end
