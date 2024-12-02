#!/bin/sh
. t/pre.sh

cleanup() {
    zfs destroy ${zfs_dataset}/releases/${release} || true
    tap_fail "unexpected error... cleaned up"
    exit 1
}

t="fetch"

sjail fetch "$release"

if [ ! -e "${zfs_mount}/releases/${release}/COPYRIGHT" ]; then
    tap_fail "$t: release fetched"
fi
tap_pass "$t: release fetched"

tap_end
