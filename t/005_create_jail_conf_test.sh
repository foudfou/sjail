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

sjail create alcatraz "${release}" >/dev/null ||suicide
grep -q addr ${jail_conf};  [ $? = 1 ]
tap_ok $? "$t: no ip in jail.conf"
grep -q -E 'interface = lo1;' ${jail_conf};
tap_ok $? "$t: loopback interface"
grep -q _hook ${jail_conf};
tap_ok $? "$t: hooks in jail.conf"
sjail destroy alcatraz >/dev/null ||suicide

sjail create alcatraz "${release}" ip4=1.2.3.4 >/dev/null ||suicide
grep -q "ip4.addr = 1.2.3.4;" ${jail_conf}
tap_ok $? "$t: ip4.addr in jail.conf"
sjail destroy alcatraz >/dev/null ||suicide

sjail create alcatraz "${release}" ip6=fd10::1 >/dev/null ||suicide
grep -q "ip6.addr = fd10::1;" ${jail_conf}
tap_ok $? "$t: ip6.addr in jail.conf"
sjail destroy alcatraz >/dev/null ||suicide

sjail create alcatraz "${release}" ip4=1.2.3.4 ip6=fd10::1 >/dev/null ||suicide
grep -q "ip6.addr = fd10::1;" ${jail_conf} && \
    grep -q "ip4.addr = 1.2.3.4;" ${jail_conf}
tap_ok $? "$t: ipx.addr in jail.conf"
sjail destroy alcatraz >/dev/null ||suicide

sjail create alcatraz "${release}" ip4=1.2.3.4 iface=vtnet0 >/dev/null ||suicide
grep -q -E 'interface = vtnet0;' ${jail_conf};
tap_ok $? "$t: shared interface"
grep -q _hook ${jail_conf};  [ $? = 1 ]
tap_ok $? "$t: no hooks in jail.conf"
sjail destroy alcatraz >/dev/null ||suicide

sjail create alcatraz "${release}" ip4=1.2.3.4 iface=lo1 >/dev/null ||suicide
grep -q -E 'interface = lo1;' ${jail_conf};
tap_ok $? "$t: loopback interface - explicit"
grep -q _hook ${jail_conf};
tap_ok $? "$t: hooks in jail.conf - explicit loopback"
sjail destroy alcatraz >/dev/null ||suicide

tap_end
