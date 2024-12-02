#!/bin/sh
. t/pre.sh

trap cleanup 1 2 3 6 15
cleanup() {
    zfs destroy ${zfs_dataset}/jails/alcatraz 2>/dev/null || true
    tap_fail "unexpected error... cleaned up"
    exit 1
}

t="destroy"

sjail create alcatraz "${release}" >/dev/null
sjail destroy alcatraz >/dev/null

if zfs list -H ${zfs_dataset}/jails/alcatraz 2>/dev/null;then
    tap_fail "$t: jail pool destroyed"
fi
tap_pass "$t: jail pool destroyed"

if $(sysrc jail_list | grep -qw alcatraz);then
    tap_fail "$t: jail removed from jail_list entry"
fi
tap_pass "$t: jail removed from jail_list entry"

tap_end
