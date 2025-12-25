#!/bin/sh
basedir=$(dirname $(realpath "$0"))

. $basedir/pre.sh

cleanup() {
    rm sjail-test.* ||true
    ssh root@"${vm1}" jail -r j02 ||true
    ssh root@"${vm1}" sjail destroy j02 ||true
    ssh root@"${vm1}" jail -r j01 ||true
    ssh root@"${vm1}" sjail destroy j01 ||true
    tap_fail "unexpected error... cleaned up"
    exit 1
}

t="jailnet"

pf='ext_if=vtnet0
bridge_net="10.0.0.0/24"

icmp_types  = "{ echoreq, unreach }"
icmp6_types = "{ echoreq, unreach, routeradv, neighbrsol, neighbradv }"

table <jails> persist

set skip on lo

rdr-anchor "rdr/*"

# Could also just use $bridge_net instead of <jails>.
nat on $ext_if from <jails> to any -> ($ext_if:0)

block in all
pass out all keep state
antispoof for $ext_if

pass inet proto icmp icmp-type $icmp_types
pass inet6 proto icmp6 icmp6-type $icmp6_types

pass from $ext_if:network to any keep state
pass in inet proto tcp from any to any port ssh flags S/SA keep state

pass on bridge0 from $bridge_net to any keep state
# pass in on bridge0 from $bridge_net to any keep state
# pass out on bridge0 to $bridge_net keep state'

jail1_ip4="10.0.0.5"
jail2_ip4="10.0.0.6"
gw4="10.0.0.1"

setup() {
    out1=$(mktemp sjail-test.XXXXXX)
    out2=$(mktemp sjail-test.XXXXXX)

    install_sjail "${vm1}" "${CONF_DEFAULT}" "${pf}"
    ssh root@${vm1} '
    ifconfig bridge0 deletem vtnet0 2>/dev/null || true
    ifconfig bridge0 destroy 2>/dev/null || true
    sysrc cloned_interfaces+="bridge0"
    sysrc ifconfig_bridge0="inet '${gw4}'/24 description jailnet up"
    sysrc gateway_enable="YES"
    service netif cloneup
    service routing restart
'
    ssh root@"${vm2}" "service pf stop" ||true
}
setup >/dev/null 2>&1

ssh root@"${vm1}" sjail create j01 "${release}" ip4=${jail1_ip4}/24 \
    vnet=1 iface=bridge0 nat=1 2>/dev/null
[ $? = 1 ]
tap_ok $? "$t: missing gw4"
ssh root@"${vm1}" sjail destroy j01 >/dev/null 2>&1

# VNET jail with private IP (isolated network)
#sjail create build 14.3-RELEASE vnet=1 ip4=10.0.0.10/24 iface=bridge0 nat=1
# Makes sense: Private VNET jail needs NAT for outbound access
new_jail ${vm1} j01 ip4=${jail1_ip4}/24 vnet=1 iface=bridge0 nat=1 gw4=${gw4}
new_jail ${vm1} j02 ip4=${jail2_ip4}/24 vnet=1 iface=bridge0 nat=1 gw4=${gw4}
conn_ext_nat_ok "build: j01 → ext" ${vm1} j01
conn_jail_vm_ok "build: j01 → vm2" ${vm2} ${vm1} j01 ${vm1} # NAT!
conn_jail_lo0_ok "build: j01 lo0" ${vm1} j01
conn_jail_jail_ok "build: j02 → j01 ok" ${vm1} j01 ${jail1_ip4} j02 ${jail2_ip4}
delete_jail ${vm1} j02
delete_jail ${vm1} j01

new_jail ${vm1} j01 ip4=${jail1_ip4}/24 vnet=1 iface=bridge0 gw4=${gw4} nat=1 rdr=1
conn_vm_jail_fail "build: vm2 → j01" ${vm1} j01 ${jail1} ${vm2}
delete_jail ${vm1} j01

tap_end
