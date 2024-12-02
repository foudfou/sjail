#!/bin/sh
. t/pre.sh

trap cleanup 1 2 3 6 15
cleanup() {
    zfs destroy ${zfs_dataset}/jails/alcatraz 2>/dev/null || true
    tap_fail "unexpected error... cleaned up"
    exit 1
}

t="create jail.conf"

jail_conf="${zfs_mount}/jails/alcatraz/jail.conf"

sjail create alcatraz "${release}" >/dev/null
if grep -q addr ${jail_conf};then
    tap_fail "$t: no ip in jail.conf"
fi
tap_pass "$t: no ip in jail.conf"
sjail destroy alcatraz >/dev/null ||suicide

sjail create alcatraz "${release}" ip4=1.2.3.4 >/dev/null
if ! grep -q "ip4.addr = 1.2.3.4;" ${jail_conf};then
    tap_fail "$t: ip4.addr in jail.conf"
fi
tap_pass "$t: ip4.addr in jail.conf"
sjail destroy alcatraz >/dev/null ||suicide

sjail create alcatraz "${release}" ip6=fd10::1 >/dev/null
if ! grep -q "ip6.addr = fd10::1;" ${jail_conf};then
    tap_fail "$t: ip6.addr in jail.conf"
fi
tap_pass "$t: ip6.addr in jail.conf"
sjail destroy alcatraz >/dev/null ||suicide

sjail create alcatraz "${release}" ip4=1.2.3.4 ip6=fd10::1 >/dev/null
if ! (grep -q "ip6.addr = fd10::1;" ${jail_conf} && \
      grep -q "ip4.addr = 1.2.3.4;" ${jail_conf});then
    tap_fail "$t: ipx.addr in jail.conf"
fi
tap_pass "$t: ipx.addr in jail.conf"
sjail destroy alcatraz >/dev/null ||suicide

tap_end
