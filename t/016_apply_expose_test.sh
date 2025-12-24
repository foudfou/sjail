#!/bin/sh
. t/pre.sh

cleanup() {
    jail -r j01 || true
    zfs destroy "${zfs_dataset}/jails/j01" || true
    rm -fr ${zfs_mount}/recipes/* || true
    tap_fail "unexpected error... cleaned up"
    exit 1
}

t="apply expose"

sjail create j01 "${release}" ip4=10.1.1.11/24 nat=1 rdr=1 >/dev/null ||suicide
jail -c j01 >/dev/null ||suicide

mkdir "${zfs_mount}/recipes/test1" ||suicide
cat <<EOF > "${zfs_mount}/recipes/test1/apply.sh"
EXPOSE tcp 1234 5555
EXPOSE udp 1234 5555
EOF


sjail apply j01 test1 >/dev/null 2>&1 ||suicide


jail_path="${zfs_mount}/jails/j01"
[ -f "${jail_path}/rdr.conf" ]
tap_ok $? "$t: rdr.conf created"

rdr=$(pfctl -a "rdr/j01" -Psn 2> /dev/null)
echo -e "${rdr}" | grep -q -E ' inet proto tcp .* 1234 -> 10.1.1.11 port 5555'
tap_ok $? "$t: rdr ip4 tcp"
echo -e "${rdr}" | grep -q -E ' inet proto udp .* 1234 -> 10.1.1.11 port 5555'
tap_ok $? "$t: rdr ip4 udp"



jail -r j01 >/dev/null 2>&1 ||suicide
sjail destroy j01 >/dev/null ||suicide
rm -fr ${zfs_mount}/recipes/* ||suicide

tap_end
