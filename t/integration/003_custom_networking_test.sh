#!/bin/sh
#set -x
# TODO test shared interface and nat=1 expose=0. I.e. host with VPN (or default
# gw is not on LAN) and jail: 1. has access to internet, 2. exposes on LAN,
# 3. does not expose on VPN.
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

t="custom networking"

setup() {
    install_sjail "${vm1}" "${CONF_DEFAULT}" "${PF_DEFAULT}"
    ssh root@${vm1} 'sysrc cloned_interfaces+="lo1 bridge0"
sysrc ifconfig_bridge0="addm vtnet0 up"
service netif cloneup'
    ssh root@"${vm2}" "service pf stop" ||true
}
setup

# ============================================================================
# HAPPY PATH - common cases, make sense and work well
# ============================================================================

out1=$(mktemp sjail-test.XXXXXX)
out2=$(mktemp sjail-test.XXXXXX)

jail1_ip4="10.0.0.5"
jail2_ip4="10.0.0.6"

# Private jail for database, needs outbound access
#sjail create db 14.3-RELEASE ip4=10.0.0.5 iface=lo1 nat=1
# Makes sense: Private IP needs NAT for pkg install, etc.
new_jail ${vm1} j01 ip4=${jail1_ip4}/24 iface=lo1 nat=1
new_jail ${vm1} j02 ip4=${jail2_ip4}/24 iface=lo1 nat=1
conn_vm_jail_fail "db: vm2 → j01 fail" ${vm1} j01 ${jail1_ip4} ${vm2}
conn_ext_nat_ok "db: j01 → ext ok" ${vm1} j01
conn_jail_jail_ok "db: j02 → j01 ok" ${vm1} j01 ${jail1_ip4} j02 ${jail2_ip4}
delete_jail ${vm1} j02
delete_jail ${vm1} j01

# Public web server on LAN
#sjail create web 14.3-RELEASE ip4=192.168.1.50/24 iface=vtnet0
# Makes sense: LAN IP, no NAT needed, directly accessible
new_jail ${vm1} j01 ip4=${jail1}/24 iface=vtnet0
conn_vm_jail_ok "web: vm2 → j01" ${vm1} j01 ${jail1} ${vm2}
conn_ext_nat_ok "web: j01 → ext" ${vm1} j01
conn_jail_vm_ok "web: j01 → vm2" ${vm2} ${vm1} j01 ${jail1}
delete_jail ${vm1} j01

# VNET jail with LAN IP (acts like physical machine on network)
#sjail create app 14.3-RELEASE vnet=1 ip4=192.168.1.60/24 iface=bridge0
# Makes sense: VNET with public IP, appears as another host on LAN
new_jail ${vm1} j01 ip4=${jail1}/24 vnet=1 iface=bridge0
conn_vm_jail_ok "app: vm2 → j01" ${vm1} j01 ${jail1} ${vm2}
conn_ext_nat_ok "app: j01 → ext" ${vm1} j01
conn_jail_vm_ok "app: j01 → vm2" ${vm2} ${vm1} j01 ${jail1}
conn_jail_lo0_ok "app: j01 lo0" ${vm1} j01
delete_jail ${vm1} j01

## FIXME need get_ip vnet support
# # VNET jail with private IP (isolated network)
# #sjail create build 14.3-RELEASE vnet=1 ip4=10.0.0.10/24 iface=bridge0 nat=1
# # Makes sense: Private VNET jail needs NAT for outbound access
# new_jail ${vm1} j01 ip4=${jail1_ip4}/24 vnet=1 iface=bridge0 nat=1
# conn_vm_jail_ok "build: vm2 → j01" ${vm1} j01 ${jail1} ${vm2}
# conn_ext_nat_ok "build: j01 → ext" ${vm1} j01
# conn_jail_vm_ok "build: j01 → vm2" ${vm2} ${vm1} j01 ${jail1}
# conn_jail_lo0_ok "build: j01 lo0" ${vm1} j01
# delete_jail ${vm1} j01

# # Dual-stack public jail
# sjail create api 14.3-RELEASE ip4=192.168.1.70/24 ip6=fd10::70/64 iface=em0
# # Makes sense: Both IPs routable, no NAT needed, common setup

# # Private jail with RDR (exposed service on private network)
# sjail create vpn 14.3-RELEASE ip4=10.0.0.20 iface=lo1 nat=1 rdr=1
# # Makes sense: Private jail but needs inbound connections (e.g., VPN server)



# # ============================================================================
# # CORNER CASES - Work but might be unusual
# # ============================================================================

# # Private jail WITHOUT NAT (fully isolated)
# sjail create sandbox 14.3-RELEASE ip4=10.0.0.30 iface=lo1
# # Works: Jail can only talk to host, no outbound access. Useful for testing.

# # Public jail with NAT (unnecessary but harmless)
# sjail create misc 14.3-RELEASE ip4=192.168.1.80/24 iface=em0 nat=1
# # Works: NAT rule created but never used since IP is already routable. Harmless.

# # VNET jail without specifying IP in sjail (configured inside jail)
# sjail create manual 14.3-RELEASE vnet=1 iface=bridge0
# # Works: Jail starts, network configured manually via exec.start or inside jail

# # Loopback jail with LAN subnet IP (weird but valid)
# sjail create weird 14.3-RELEASE ip4=192.168.1.90/24 iface=lo1 nat=1
# # Works: Technically valid, but confusing. Why use lo1 with LAN IP?

# # ============================================================================
# # MULTI-IP CASES - Limited support, edge cases
# # ============================================================================

# # Multiple LAN IPs (virtual hosting scenario)
# sjail create multi 14.3-RELEASE ip4="192.168.1.81/24,192.168.1.82/24" iface=em0
# # Works: Both IPs added as aliases. No NAT needed. Use case: multiple services.

# # Ez-jail pattern: loopback + LAN (legacy but still works)
# sjail create legacy 14.3-RELEASE ip4="lo1|127.0.1.10,em0|192.168.1.85/24"
# # Works: But NAT/RDR apply to BOTH IPs! Probably want NAT only for 127.0.1.10.
# # Limitation: sjail can't differentiate which IP needs NAT.

# # Ez-jail pattern with NAT
# sjail create legacy2 ip4="lo1|127.0.1.11,em0|192.168.1.86/24" nat=1
# # Problematic: NAT applied to both 127.0.1.11 AND 192.168.1.86
# # The LAN IP doesn't need NAT! This is the multi-IP limitation.

# # Multiple private IPs on loopback
# sjail create multi-priv ip4="lo1|10.0.0.40,lo1|10.0.0.41" nat=1
# # Works: Both private IPs NAT'd. Use case unclear, but technically valid.

# # Dual-stack with one private, one public (unusual)
# sjail create mixed 14.3-RELEASE ip4=10.0.0.50 ip6=2001:db8::50/64 iface=lo1 nat=1
# # Problematic: NAT applies to both! IPv6 probably doesn't need NAT.
# # Better: Use two separate jails or pure IPv6.

# # ============================================================================
# # UNEXPECTED BEHAVIOR - Things that might surprise users
# # ============================================================================

# # VNET with shared interface (not a bridge)
# sjail create confusion 14.3-RELEASE vnet=1 ip4=192.168.1.100/24 iface=em0
# # Unexpected: This tries to give the PHYSICAL em0 to the jail!
# # The jail would steal em0 from the host. Almost never what you want.
# # Should use: iface=bridge0 (or em0bridge if using jib)

# # Loopback jail with public IP but forgot NAT
# sjail create forgot 14.3-RELEASE ip4=10.0.0.60 iface=lo1
# # Works but broken: Jail has no outbound connectivity. User probably forgot nat=1.

# # RDR without NAT (incomplete setup)
# sjail create incomplete 14.3-RELEASE ip4=10.0.0.70 iface=lo1 rdr=1
# # Problematic: RDR forwards inbound, but jail can't respond without NAT.
# # Usually want: nat=1 rdr=1 together.

# # VNET jail on lo1 (doesn't make sense)
# sjail create nonsense 14.3-RELEASE vnet=1 ip4=10.0.0.80 iface=lo1
# # Unexpected: VNET needs epairs and bridges, not loopback interfaces.
# # This probably fails or behaves strangely.

# # Multiple IPs with RDR
# sjail create multi-rdr ip4="10.0.0.90,10.0.0.91" iface=lo1 nat=1 rdr=1
# # Problematic: Which IP does RDR forward to? First one? Both?
# # sjail limitation: Can't specify per-IP RDR rules.

# # ============================================================================
# # INVALID / WILL FAIL - These don't work
# # ============================================================================

# # VNET without iface
# sjail create broken 14.3-RELEASE vnet=1 ip4=192.168.1.110/24
# # Fails: VNET needs an interface/bridge to attach to.

# # No IP specified for non-VNET jail
# sjail create noip 14.3-RELEASE iface=em0
# # Fails: Shared/loopback jails need an IP address.

# # Mixing IPv4 address families on different interfaces with different needs
# sjail create complex 14.3-RELEASE ip4="lo1|10.0.0.100,em0|192.168.1.120/24" nat=1 rdr=1
# # Works but broken: NAT/RDR apply to BOTH IPs. The LAN IP doesn't need either!
# # This is THE multi-IP limitation. Better: Use separate jails.

tap_end
