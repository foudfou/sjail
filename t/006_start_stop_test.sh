#!/bin/sh
. t/pre.sh

cleanup() {
    jail -r alcatraz || true
    zfs destroy ${zfs_dataset}/jails/alcatraz || true
    tap_fail "unexpected error... cleaned up"
    exit 1
}

t="start stop"

sjail create alcatraz "${release}" ip4=10.1.1.11 ip6=fd10::11 nat=1 >/dev/null ||suicide

# --- Start ---

jail -c alcatraz >/dev/null ||suicide

jls -j alcatraz >/dev/null 2>&1
tap_ok $? "$t: jail running"

pf_table=$(pfctl -q -t jails -T show)
echo -e "${pf_table}" | grep -q 10.1.1.11
tap_ok $? "$t: pf table ip4 entry"
echo -e "${pf_table}" | grep -q fd10::11
tap_ok $? "$t: pf table ip6 entry"

ok=$(sjail destroy alcatraz 2>&1 || true)
echo $ok | grep -q "jail running"
tap_ok $? "$t: prevent destroy running jail"

# --- Stop ---

jail -r alcatraz >/dev/null

ok=$(jls -j alcatraz  2>&1 ||true)
echo -e $ok | grep -q 'jail "alcatraz" not found'
tap_ok $? "$t: jail still running"

pf_table=$(pfctl -q -t jails -T show)
echo -e "${pf_table}" | grep -q 10.1.1.11; [ $? = 1 ]
tap_ok $? "$t: pf table ip4 entry removed"
echo -e "${pf_table}" | grep -q fd10::11; [ $? = 1 ]
tap_ok $? "$t: pf table ip6 entry removed"

sjail destroy alcatraz >/dev/null

tap_end
