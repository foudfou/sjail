#!/bin/sh

trap cleanup 1 2 3 6 15
cleanup() {
    zfs destroy -r ${zfs_pool} || true
    echo "Done cleanup ... quitting."
}

test_init() {
    local t=test_init

    sjail init

    if ! zfs list -H ${zfs_pool} >/dev/null;then
        fail "$t: missing zpool"
    fi

    if ! zfs list -H ${zfs_pool}/recipes >/dev/null;then
        fail "$t: missing recipe zpool"
    fi

    # FIXME how do we not mess with main /etc/jail.conf? vm?
    if ! grep -q '.include "'${zfs_mount}/jails /etc/jail.conf;then
        fail "$t: missing .include in /etc/jails.conf"
    fi

    if ! sysrc -c jail_enable="YES";then
        fail "$t: incorrect sysrc jail_enable"
    fi

    if ! sysrc -c cloned_interfaces+="${loopback}";then
        fail "$t: missing sysrc cloned_interfaces"
    fi

    ok $t
}
test_init
