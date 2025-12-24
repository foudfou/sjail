#!/bin/sh

###############################################################################
# Global test variables
#

# Make sure this is consistent with the guest system
release="15.0-RELEASE"

# Test jail assigned IP. VNET expects an IP in the bridge network.
test_jail_ip4=192.168.1.112
###############################################################################

if [ "$(sysctl -n security.jail.jailed)" -eq 0 -a \
     "$(sysctl -n kern.vm_guest)" = none ]; then
    echo "Not inside isolated environment. Please run inside jail or vm."
    exit 1
fi

trap cleanup 1 2 3 6 15
cleanup() { # re-defined inside tests
    echo "done cleanup ... quitting."
}

suicide() { # intended for non-test commands
    kill -HUP $$
}

. /usr/local/etc/sjail.conf

. t/tap.sh

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
