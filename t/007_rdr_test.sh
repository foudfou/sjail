#!/bin/sh
. t/pre.sh

cleanup() {
    jail -r alcatraz || true
    zfs destroy ${zfs_dataset}/jails/alcatraz || true
    tap_fail "unexpected error... cleaned up"
    exit 1
}

t="rdr"

sjail create alcatraz "${release}" ip4=10.1.1.11 ip6=fd10::11 >/dev/null ||suicide

# testing whitespace
echo "   	" >> ${zfs_mount}/jails/alcatraz/rdr.conf
cat <<EOF  >> "${zfs_mount}/jails/alcatraz/rdr.conf"
# comments allowed
tcp 1234 5555

udp 1234 5555
EOF

# --- Start ---

jail -c alcatraz >/dev/null ||suicide

rdr=$(pfctl -a "rdr/alcatraz" -Psn 2> /dev/null)
echo -e "${rdr}" | grep -q -E ' inet .* 1234 -> 10.1.1.11 port 5555'
tap_ok $? "$t: rdr ip4"
echo -e "${rdr}" | grep -q  ' inet6 .* 1234 -> fd10::11 port 5555'
tap_ok $? "$t: rdr ip6"

# --- Stop ---

jail -r alcatraz >/dev/null 2>&1 ||suicide

rdr=$(pfctl -a "rdr/alcatraz" -Psn 2> /dev/null)
echo -e "${rdr}" | grep -q -E ' inet .* 1234 -> 10.1.1.11 port 5555'; [ $? = 1 ]
tap_ok $? "$t: rdr ip4 rule removed"
echo -e "${rdr}" | grep -q ' inet6 .* 1234 -> fd10::11 port 5555'; [ $? = 1 ]
tap_ok $? "$t: rdr ip6 rule removed"

sjail destroy alcatraz >/dev/null ||suicide

tap_end
