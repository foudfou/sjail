#!/bin/sh
. t/pre.sh

cleanup() {
    zfs destroy ${zfs_dataset}/jails/alcatraz 2>/dev/null || true
    tap_fail "unexpected error... cleaned up"
    exit 1
}

t="create"

sjail create alcatraz "${release}" >/dev/null ||suicide

zfs list -H ${zfs_dataset}/jails/alcatraz >/dev/null
tap_ok $? "$t: jail dataset created"

[ -d ${zfs_mount}/jails/alcatraz ]
tap_ok $? "$t: jail mounted"

jail_path="${zfs_mount}/jails/alcatraz"
[ -e ${jail_path}/fstab -a \
  -e ${jail_path}/root -a \
  -e ${jail_path}/jail.conf ]
tap_ok $? "$t: jail files"

# sysrc -c doesn't seem to work well for lists
sysrc jail_list | grep -qw alcatraz
tap_ok $? "$t: sysrc jail_list"

zfs destroy ${zfs_dataset}/jails/alcatraz ||suicide

tap_end
