#!/bin/sh

#
# Global test variables
#
release="15.0-RELEASE"

# Fresh FreeBSD installs.
vm1=192.168.1.202
vm2=192.168.1.203
jail1=192.168.1.205
jail1_lo=127.0.1.5

#
# Utils
#

trap cleanup 1 2 3 6 15
cleanup() { # re-defined inside tests
    echo "done cleanup ... quitting."
}

suicide() { # intended for non-test commands
    kill -HUP $$
}

. t/tap.sh


#
# Common
#
zfs_sjail="zroot/sjail"
CONF_DEFAULT='zfs_dataset="'${zfs_sjail}'"
zfs_mount="/sjail"
interface="vtnet0"
ext_if=""'

PF_DEFAULT='ext_if=vtnet0
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

# Allow local network
pass from $ext_if:network to any keep state

# Allow ssh
pass in inet proto tcp from any to any port ssh flags S/SA keep state'

install_sjail() {
    local vm=$1
    local conf=$2
    local pf=$3

    file_list="sjail/makefile sjail/src"
    tar cf - -C $basedir/../../.. ${file_list} \
        | ssh root@"${vm}" tar xf -

    ssh root@"${vm}" "cd sjail && make install"

    echo "${conf}" | ssh root@"${vm}" -T "cat > /usr/local/etc/sjail.conf"

    setup_pf "${vm}" "${pf}"

    ssh root@"${vm}" "sjail init" ||true
}

setup_pf() {
    local vm=$1
    local pf=$2

    echo "${pf}" | ssh root@"${vm}" -T "cat > /etc/pf.conf"
    ssh root@"${vm}" "service pf reload" ||true
}

new_jail() {
    local vm=$1; shift
    local jail=$1; shift
    local args="$*"

    ssh root@"${vm1}" sjail create "${jail}" "${release}" $args
    ssh root@"${vm1}" jail -c "${jail}"
}

delete_jail() {
    local vm=$1; shift
    local jail=$1; shift

    rm sjail-test.*
    ssh root@"${vm}" jail -r ${jail}
    ssh root@"${vm}" zfs unmount -f ${zfs_mount}/jails/${jail}
    ssh root@"${vm}" sjail destroy ${jail} || \
        ssh root@"${vm}" zfs destroy -f ${zfs_sjail}/jails/${jail}
}

# conn_ functions assume temp files created.
conn_vm_jail_fail() {
    local t_name=$1; shift
    local vm_srv=$1; shift
    local jail_srv=$1; shift
    local jail_srv_ip4=$1; shift
    local vm_cli=$1; shift

    ssh root@"${vm_srv}" "timeout 2 jexec -l ${jail_srv} nc -v -l 5555" >$out1 2>&1 &
    pid=$!
    sleep .5
    ssh root@"${vm_cli}" nc -v -w 1 -z "${jail_srv_ip4}" 5555 >$out2 2>&1
    wait $pid
    grep -qE "connect to ${jail_srv_ip4} port 5555 \(tcp\) failed: Operation timed out" $out2
    tap_ok $? "$t: ${t_name}"
}

conn_vm_jail_ok() {
    local t_name=$1; shift
    local vm_srv=$1; shift
    local jail_srv=$1; shift
    local jail_srv_ip4=$1; shift
    local vm_cli=$1; shift

    ssh root@"${vm_srv}" jexec -l ${jail_srv} timeout 2 nc -v -l 5555 >$out1 2>&1 &
    pid=$!
    sleep .5
    ssh root@"${vm_cli}" nc -v -w 1 -z ${jail_srv_ip4} 5555 >$out2 2>&1
    wait $pid
    grep -qE "Connection from ${vm_cli} .* received!" $out1
    tap_ok $? "$t: ${t_name} received"
    grep -qE "Connection to ${jail_srv_ip4} 5555 port \[tcp/personal-agent\] succeeded!" $out2
    tap_ok $? "$t: ${t_name} sent"
}

conn_jail_vm_ok() {
    local t_name=$1; shift
    local vm_srv=$1; shift
    local vm_cli=$1; shift
    local jail_cli=$1; shift
    local jail_cli_ip4=$1; shift

    ssh root@"${vm_srv}" timeout 2 nc -v -l 5555 >$out1 2>&1 &
    pid=$!
    sleep .5
    ssh root@"${vm_cli}" jexec -l ${jail_cli} nc -v -w 1 -z ${vm_srv} 5555 >$out2 2>&1
    wait $pid
    grep -qE "Connection from ${jail_cli_ip4} .* received!" $out1
    tap_ok $? "$t: ${t_name} received"
    grep -qE "Connection to ${vm_srv} 5555 port \[tcp/personal-agent\] succeeded!" $out2
    tap_ok $? "$t: ${t_name} sent"
}

conn_jail_jail_ok() {
    local t_name=$1; shift
    local vm=$1; shift
    local jail_srv=$1; shift
    local jail_srv_ip4=$1; shift
    local jail_cli=$1; shift
    local jail_cli_ip4=$1; shift

    ssh root@"${vm}" jexec -l ${jail_srv} timeout 2 nc -v -l 5555 >$out1 2>&1 &
    pid=$!
    sleep .5
    ssh root@"${vm}" jexec -l ${jail_cli} nc -v -w 1 -z ${jail_srv_ip4} 5555 >$out2 2>&1
    wait $pid
    grep -qE "Connection from ${jail_cli_ip4} .* received!" $out1
    tap_ok $? "$t: ${t_name} received"
    grep -qE "Connection to ${jail_srv_ip4} 5555 port \[tcp/personal-agent\] succeeded!" $out2
    tap_ok $? "$t: ${t_name} sent"
}

conn_jail_lo0_ok() {
    local t_name=$1; shift
    local vm=$1; shift
    local jail=$1; shift

    ssh root@"${vm}" jexec -l ${jail} timeout 2 nc -v -l 5555 >$out1 2>&1 &
    pid=$!
    sleep .5
    ssh root@"${vm}" jexec -l ${jail} nc -v -w 1 -z 127.0.0.1 5555 >$out2 2>&1
    wait $pid
    grep -qE "Connection from localhost .* received!" $out1
    tap_ok $? "$t: ${t_name} received"
    grep -qE "Connection to 127.0.0.1 5555 port \[tcp/personal-agent\] succeeded!" $out2
    tap_ok $? "$t: ${t_name} sent"
}

conn_ext_nat_ok() {
    local t_name=$1; shift
    local vm=$1; shift
    local jail=$1; shift

    ssh root@"${vm}" jexec -l ${jail} fetch -o /dev/null https://www.freebsd.org/ >$out1 2>&1
    tap_ok $? "$t: ${t_name}"
}
