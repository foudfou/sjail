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

# Just making sure
sed -ie 's/interface=.*/interface="lo1"/' /usr/local/etc/sjail.conf

sjail create alcatraz "${release}" >/dev/null ||suicide
grep -q addr ${jail_conf};  [ $? = 1 ]
tap_ok $? "$t: no ip"
grep -q -E 'interface = lo1;' ${jail_conf};
tap_ok $? "$t: loopback interface"
grep -q _pf ${jail_conf};
tap_ok $? "$t: hooks"
sjail destroy alcatraz >/dev/null ||suicide

sjail create alcatraz "${release}" ip4=1.2.3.4/24 >/dev/null ||suicide
grep -q "ip4.addr = 1.2.3.4/24;" ${jail_conf}
tap_ok $? "$t: ip4.addr"
sjail destroy alcatraz >/dev/null ||suicide

sjail create alcatraz "${release}" ip6=fd10::1/64 >/dev/null ||suicide
grep -q "ip6.addr = fd10::1/64;" ${jail_conf}
tap_ok $? "$t: ip6.addr"
sjail destroy alcatraz >/dev/null ||suicide

sjail create alcatraz "${release}" ip4=1.2.3.4/24 ip6=fd10::1/64 >/dev/null ||suicide
grep -q "ip6.addr = fd10::1/64;" ${jail_conf} && \
    grep -q "ip4.addr = 1.2.3.4/24;" ${jail_conf}
tap_ok $? "$t: ipx.addr"
sjail destroy alcatraz >/dev/null ||suicide

sed -ie 's/interface=.*/interface="vtnet0"/' /usr/local/etc/sjail.conf
sjail create alcatraz "${release}" ip4=1.2.3.4/24 >/dev/null ||suicide
grep -q -E 'interface = vtnet0;' ${jail_conf};
tap_ok $? "$t: shared interface"
grep -q _pf ${jail_conf}
tap_ok $? "$t: hooks for shared interface"
sjail destroy alcatraz >/dev/null ||suicide

sed -ie 's/interface=.*/interface="lo1"/' /usr/local/etc/sjail.conf
sjail create alcatraz "${release}" ip4=1.2.3.4/24 >/dev/null ||suicide
grep -q -E 'interface = lo1;' ${jail_conf};
tap_ok $? "$t: loopback interface - explicit"
grep -q _pf ${jail_conf}
tap_ok $? "$t: hooks for loopback - explicit loopback"
sjail destroy alcatraz >/dev/null ||suicide

tap_end
