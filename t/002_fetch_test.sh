#!/bin/sh

test_fetch() {
    local t=test_fetch

    sjail fetch 14.1-RELEASE

    if [ ! -e ${zfs_mount}/releases/14.1-RELEASE/COPYRIGHT ]; then
        fail "$t: release fetch incomplete"
    fi

    ok $t
}
test_fetch
