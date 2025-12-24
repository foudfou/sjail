#!/bin/sh
. t/pre.sh

cleanup() {
    zfs destroy "${zfs_dataset}/jails/j01" || true
    tap_fail "unexpected error... cleaned up"
    exit 1
}

t="release destroy"

sjail create j01 "${release}" ip4=10.1.1.11/24 >/dev/null ||suicide

sjail rel-destroy "${release}" >/dev/null 2>&1; [ $? -ne 0 ]
tap_ok $? "$t: prevent dependent release destroy"

zfs destroy "${zfs_dataset}/jails/j01" ||suicide

tap_end
