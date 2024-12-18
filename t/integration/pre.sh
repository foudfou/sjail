#!/bin/sh

trap cleanup 1 2 3 6 15
cleanup() { # re-defined inside tests
    echo "done cleanup ... quitting."
}

suicide() { # intended for non-test commands
    kill -HUP $$
}

. t/tap.sh

#
# Global test variables
#
release="14.1-RELEASE"

# Fresh FreeBSD installs.
vm1=192.168.1.202
vm2=192.168.1.203
jail1=192.168.1.205
