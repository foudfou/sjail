#!/bin/sh
#
# cat <<EOF > /usr/local/etc/sjail.conf
# zfs_dataset="zroot/sjail"
# zfs_mount="/jails"
# loopback="lo1"
# pf_ext_if="ext_if"
# EOF
# make install
# sjail init
#
set -e

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
    echo "not ok unexpected error"
    kill -HUP $$
}

. /usr/local/etc/sjail.conf

. t/tap.sh

#
# Global test variables
#
release="14.1-RELEASE"
