#!/bin/sh

trap cleanup 1 2 3 6 15
cleanup() {
    zfs destroy ${zfs_dataset}/jails/alcatraz 2>/dev/null || true
    echo "Done cleanup ... quitting."
}

test_destroy() {
    local t=test_destroy

    sjail create alcatraz 14.1-RELEASE >/dev/null
    sjail destroy alcatraz >/dev/null

    if zfs list -H ${zfs_dataset}/jails/alcatraz 2>/dev/null;then
        fail "$t: jail pool not destroyed"
    fi

    if $(sysrc jail_list | grep -qw alcatraz);then
        fail "$t: jail not removed from jail_list entry"
    fi

    ok $t
}
test_destroy
