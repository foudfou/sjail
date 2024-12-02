#!/bin/sh

trap cleanup 1 2 3 6 15
cleanup() {
    zfs destroy ${zfs_dataset}/jails/alcatraz 2>/dev/null || true
    echo "Done cleanup ... quitting."
}

test_create_jail_conf() {
    local t=test_create_jail_conf

    local jail_conf="${zfs_mount}/jails/alcatraz/jail.conf"

    sjail create alcatraz 14.1-RELEASE >/dev/null
    if grep -q addr ${jail_conf};then
        fail "$t: unexpected parameter in jail.conf"
    fi
    sjail destroy alcatraz >/dev/null

    sjail create alcatraz 14.1-RELEASE ip4=1.2.3.4 >/dev/null
    if ! grep -q "ip4.addr = 1.2.3.4;" ${jail_conf};then
        fail "$t: missing parameter ip4.addr in jail.conf"
    fi
    sjail destroy alcatraz >/dev/null

    sjail create alcatraz 14.1-RELEASE ip6=fd10::1 >/dev/null
    if ! grep -q "ip6.addr = fd10::1;" ${jail_conf};then
        fail "$t: missing parameter ip6.addr in jail.conf"
    fi
    sjail destroy alcatraz >/dev/null

    sjail create alcatraz 14.1-RELEASE ip4=1.2.3.4 ip6=fd10::1 >/dev/null
    if ! (grep -q "ip6.addr = fd10::1;" ${jail_conf} && \
              grep -q "ip4.addr = 1.2.3.4;" ${jail_conf});then
        fail "$t: missing parameter ipx.addr in jail.conf"
    fi
    sjail destroy alcatraz >/dev/null

    ok $t
}
test_create_jail_conf
