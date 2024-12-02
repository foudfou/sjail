#!/bin/sh

trap cleanup 1 2 3 6 15
cleanup() {
    zfs destroy ${zfs_dataset}/jails/alcatraz 2>/dev/null || true
    echo "Done cleanup ... quitting."
}

test_create() {
    local t=test_create

    sjail create alcatraz 14.1-RELEASE >/dev/null

    if ! zfs list -H ${zfs_dataset}/jails/alcatraz >/dev/null;then
        fail "$t: missing jail alcatraz"
    fi

    if [ ! -d ${zfs_mount}/jails/alcatraz ]; then
        fail "$t: jail not mounted"
    fi

    local jail_path="${zfs_mount}/jails/alcatraz"
    if [ ! -e ${jail_path}/fstab -o \
         ! -e ${jail_path}/root -o \
         ! -e ${jail_path}/jail.conf ]; then
        fail "$t: missing jail files"
    fi

    # sysrc -c doesn't seem to work well for lists
    if ! $(sysrc jail_list | grep -qw alcatraz);then
        fail "$t: missing sysrc jail_list entry"
    fi

    zfs destroy ${zfs_dataset}/jails/alcatraz

    ok $t
}
test_create
