#!/bin/sh
. t/pre.sh

cleanup() {
    zfs destroy ${zfs_dataset}/jails/alcatraz 2>/dev/null || true
    tap_fail "unexpected error... cleaned up"
    exit 1
}

t="create"

sjail create alcatraz "${release}" >/dev/null ||suicide

if ! zfs list -H ${zfs_dataset}/jails/alcatraz >/dev/null;then
    tap_fail "$t: jail dataset created"
fi
tap_pass "$t: jail dataset created"

if [ ! -d ${zfs_mount}/jails/alcatraz ]; then
    tap_fail "$t: jail mounted"
fi
tap_pass "$t: jail mounted"

jail_path="${zfs_mount}/jails/alcatraz"
if [ ! -e ${jail_path}/fstab -o \
       ! -e ${jail_path}/root -o \
       ! -e ${jail_path}/jail.conf ]; then
    tap_fail "$t: jail files"
fi
tap_pass "$t: jail files"

# sysrc -c doesn't seem to work well for lists
if ! $(sysrc jail_list | grep -qw alcatraz);then
    tap_fail "$t: sysrc jail_list"
fi
tap_pass "$t: sysrc jail_list"

zfs destroy ${zfs_dataset}/jails/alcatraz ||suicide

tap_end
