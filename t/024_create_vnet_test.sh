#!/bin/sh
. t/pre.sh

cleanup() {
    jail -r j01 || true
    ifconfig e0b_j01 destroy || true
    zfs destroy ${zfs_dataset}/jails/j01 2>/dev/null || true
    tap_fail "unexpected error... cleaned up"
    exit 1
}

t="create vnet"

ifconfig bridge0 > /dev/null
rv=$?
if [ "$rv" -eq 0 ]; then
    tap_pass "$t: bridge0 REQUIRED"
else
    tap_fail "$t: bridge0 REQUIRED"
    tap_end
fi

sjail create j01 "${release}" ip4=${test_jail_ip4} vnet=bridge0 >/dev/null ||suicide

jail_path="${zfs_mount}/jails/j01"
grep -q vnet "${jail_path}/jail.conf"
tap_ok $? "$t: conf vnet"

grep -q "vnet=bridge0" "${jail_path}/meta.conf"
tap_ok $? "$t: meta bridge0"

jail -c j01 >/dev/null ||suicide

ifconfig e0a_j01 >/dev/null
tap_ok $? "$t: epair created"

icfg=$(jexec -l j01 ifconfig e0b_j01)
tap_ok $? "$t: jail started"
mac1=$(echo "$icfg" | grep -E '\sether ')

jexec -l j01 ifconfig e0b_j01 | grep -q -E '\sinet '${test_jail_ip4}' '
tap_ok $? "$t: ip4 set"

jexec -l j01 netstat -4rn | grep -qw 'default'
tap_ok $? "$t: default route set"

jail -r j01 >/dev/null 2>&1 ||suicide


ifconfig e0a_j01 >/dev/null 2>&1 ;  [ $? = 1 ]
tap_ok $? "$t: epair destroyed"


jail -c j01 >/dev/null ||suicide
mac2=$(jexec -l j01 ifconfig e0b_j01 | grep -E '\sether ')
tap_cmp "$mac1" "$mac2" "$t: deterministic mac"
jail -r j01 >/dev/null 2>&1 ||suicide


zfs destroy ${zfs_dataset}/jails/j01 ||suicide

tap_end
