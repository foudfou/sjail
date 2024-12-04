#!/bin/sh
. t/pre.sh

cleanup() {
    zfs destroy ${zfs_dataset}/releases/${release} || true
    tap_fail "unexpected error... cleaned up"
    exit 1
}

t="release create"

NOFETCH=""
sjail rel-create "$release" "${NOFETCH}" >/dev/null ||suicide

[ -e "${zfs_mount}/releases/${release}/COPYRIGHT" ]
tap_ok $? "$t: release fetched"

tap_end
