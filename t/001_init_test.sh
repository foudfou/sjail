#!/bin/sh
. t/pre.sh

cleanup() {
    zfs destroy -r ${zfs_dataset} || true
    tap_fail "unexpected error... cleaned up"
    exit 1
}

t="init"

sjail init ||suicide

if ! zfs list -H ${zfs_dataset} >/dev/null;then
    tap_fail "$t: zpool created"
fi
tap_pass "$t: zpool created"

if ! zfs list -H ${zfs_dataset}/recipes >/dev/null;then
    tap_fail "$t: recipe zpool created"
fi
tap_pass "$t: recipe zpool created"

if ! grep -q '.include "'${zfs_mount}/jails /etc/jail.conf;then
    tap_fail "$t: .include in /etc/jails.conf"
fi
tap_pass "$t: .include in /etc/jails.conf"

if ! sysrc -c jail_enable="YES";then
    tap_fail "$t: sysrc jail_enable"
fi
tap_pass "$t: sysrc jail_enable"

if ! sysrc -c cloned_interfaces+="${loopback}";then
    tap_fail "$t: sysrc cloned_interfaces"
fi
tap_pass "$t: sysrc cloned_interfaces"

tap_end
