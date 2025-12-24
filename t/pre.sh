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
