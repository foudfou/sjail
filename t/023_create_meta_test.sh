#!/bin/sh
. t/pre.sh

cleanup() {
    jail -r j01 || true
    zfs destroy ${zfs_dataset}/jails/j01 2>/dev/null || true
    tap_fail "unexpected error... cleaned up"
    exit 1
}

t="create"

sjail create j01 "${release}" ip4=10.1.1.11 nat=1 rdr=0 >/dev/null ||suicide

jail_path="${zfs_mount}/jails/j01"
[ -e ${jail_path}/meta.conf ]
tap_ok $? "$t: meta created"

echo "tcp 5555 5555" > /sjail/jails/j01/rdr.conf

jail -c j01 >/dev/null ||suicide

pf_table=$(pfctl -q -t jails -T show)
echo -e "${pf_table}" | grep -q 10.1.1.11
tap_ok $? "$t: pf table ip4 entry"

rdr=$(pfctl -a "rdr/j01" -Psn 2> /dev/null)
[ -z "$rdr" ]
tap_ok $? "$t: rdr empty"

jail -r j01 >/dev/null 2>&1 ||suicide


zfs destroy ${zfs_dataset}/jails/j01 ||suicide

tap_end
