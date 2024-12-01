#!/bin/sh
#
# cat <<EOF > /usr/local/etc/sjail.conf
# zfs_pool="zroot/sjail"
# zfs_mount="/jails"
# loopback="lo1"
# pf_ext_if="ext_if"
# EOF
# make install
# sjail init
#
set -eu

if [ "$(sysctl -n security.jail.jailed)" -eq 0 -a \
     "$(sysctl -n kern.vm_guest)" = none ]; then
    echo "Not inside isolated environment. Please run inside jail or vm."
    exit 1
fi

trap cleanup 1 2 3 6 15
cleanup() { # re-defined inside tests
    echo "Done cleanup ... quitting."
}

. /usr/local/etc/sjail.conf

fail() {
    echo "❌ $1"
    cleanup
    exit 1
}
ok() {
    echo "✔ $1"
}
suicide() { # intended for non-test commands
    echo "❌ unexpected error"
    kill -HUP $$
}

for f in "$@";do
    echo "  -- Starting $f"
    . $f
done
