#!/bin/sh
. t/pre.sh

cleanup() {
    jail -r j-test || true
    ifconfig e0b_j_test destroy || true
    zfs destroy ${zfs_dataset}/jails/j-test 2>/dev/null || true
    tap_fail "unexpected error... cleaned up"
    exit 1
}

# Check jail names with compliant jail/hostname constraints but non-compliant
# with shell-var (as may be used in rc.conf) are handled correctly.
t="create alphanum"

ifconfig bridge0 > /dev/null
rv=$?
if [ "$rv" -eq 0 ]; then
    tap_pass "$t: bridge0 REQUIRED"
else
    tap_fail "$t: bridge0 REQUIRED"
    tap_end
fi

sjail create j-test "${release}" ip4=${test_jail_ip4}/24 vnet=1 gw4=${test_jail_gw4} iface=bridge0 >/dev/null ||suicide

jail_path="${zfs_mount}/jails/j-test"
grep -q vnet "${jail_path}/jail.conf"
tap_ok $? "$t: conf vnet"

jail -c j-test >/dev/null ||suicide

ifconfig e0a_j_test >/dev/null
tap_ok $? "$t: epair created"

icfg=$(jexec -l j-test ifconfig e0b_j_test)
tap_ok $? "$t: jail started"

jail -r j-test >/dev/null 2>&1 ||suicide

ifconfig e0a_j_test >/dev/null 2>&1 ;  [ $? = 1 ]
tap_ok $? "$t: epair destroyed"

zfs destroy ${zfs_dataset}/jails/j-test ||suicide



sjail create j-test "${release}" ip4=${test_jail_ip4}/24 nat=1 >/dev/null ||suicide

jail -c j-test >/dev/null ||suicide
tap_ok $? "$t: jail started"

jail -r j-test >/dev/null 2>&1 ||suicide
tap_ok $? "$t: jail stopped"

zfs destroy ${zfs_dataset}/jails/j-test ||suicide


tap_end
