#!/bin/sh

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

#
# Global test variables
#
release="14.1-RELEASE"
