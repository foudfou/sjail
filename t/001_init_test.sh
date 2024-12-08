#!/bin/sh
. t/pre.sh

cleanup() {
    zfs destroy -r ${zfs_dataset} || true
    tap_fail "unexpected error... cleaned up"
    exit 1
}

t="init"

sjail init ||suicide

zfs list -H ${zfs_dataset} >/dev/null
tap_ok $? "$t: zpool created"

zfs list -H ${zfs_dataset}/recipes >/dev/null
tap_ok $? "$t: recipe zpool created"

grep -q '.include "'${zfs_mount}/jails /etc/jail.conf
tap_ok $? "$t: .include in /etc/jails.conf"

sysrc -c jail_enable="YES"
tap_ok $? "$t: sysrc jail_enable"

sysrc -c cloned_interfaces+="${interface}"
tap_ok $? "$t: CLONED INTERFACE IS REQUIRED FOR TESTS"

tap_end
