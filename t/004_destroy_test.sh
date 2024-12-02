#!/bin/sh
. t/pre.sh

trap cleanup 1 2 3 6 15
cleanup() {
    zfs destroy ${zfs_dataset}/jails/alcatraz 2>/dev/null || true
    tap_fail "unexpected error... cleaned up"
    exit 1
}

t="destroy"

sjail create alcatraz "${release}" >/dev/null ||suicide
sjail destroy alcatraz >/dev/null ||suicide

zfs list -H ${zfs_dataset}/jails/alcatraz 2>/dev/null; [ $? -ne 0 ]
tap_ok $? "$t: jail pool destroyed"

sysrc jail_list | grep -qw alcatraz; [ $? -ne 0 ]
tap_ok $? "$t: jail removed from jail_list entry"

tap_end
