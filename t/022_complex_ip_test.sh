#!/bin/sh
. t/pre.sh

cleanup() {
    jail -r j01 || true
    zfs destroy ${zfs_dataset}/jails/j01 || true
    tap_fail "unexpected error... cleaned up"
    exit 1
}

t="complex ip"

addr4="lo1|127.0.1.1,vtnet0|192.168.1.81/24"
# Not sure about use cases with multiple ip6 and on different interfaces.
addr6="lo1|fd10::1,vtnet0|fd10::2/24"
sjail create j01 "${release}" ip4="${addr4}" ip6="${addr6}" >/dev/null ||suicide

jail_conf="${zfs_mount}/jails/j01/jail.conf"
grep -q "ip4.addr = ${addr4};" ${jail_conf}
tap_ok $? "$t: ip4.addr defined"


cat <<EOF  >> "${zfs_mount}/jails/j01/rdr.conf"
tcp 1234 5555
EOF

# --- Start ---

jail -c j01 >/dev/null 2>&1 ||suicide

pf_table=$(pfctl -q -t jails -T show)

ips="127.0.1.1 192.168.1.81 fd10::1 fd10::2"
for want in ${ips}; do
    echo -e "${pf_table}" | grep -qw "${want}"
    tap_ok $? "$t: pf table ip4 entry added: ${want}"
done


rdr=$(pfctl -a "rdr/j01" -Psn 2> /dev/null)
echo -e "${rdr}" | grep -q -E ' inet .* 1234 -> 127.0.1.1 port 5555'
tap_ok $? "$t: rdr ip4 added"
echo -e "${rdr}" | grep -q  ' inet6 .* 1234 -> fd10::1 port 5555'
tap_ok $? "$t: rdr ip6 added"

# --- Stop ---

jail -r j01 >/dev/null 2>&1 ||suicide

pf_table=$(pfctl -q -t jails -T show)
for want in ${ips}; do
    echo -e "${pf_table}" | grep -qw "${want}"; [ $? = 1 ]
    tap_ok $? "$t: pf table ip4 entry removed: ${want}"
done


rdr=$(pfctl -a "rdr/j01" -Psn 2> /dev/null)
echo -e "${rdr}" | grep -q -E ' inet .* 1234 -> 127.0.1.1 port 5555'; [ $? = 1 ]
tap_ok $? "$t: rdr ip4 removed"
echo -e "${rdr}" | grep -q  ' inet6 .* 1234 -> fd10::1 port 5555'; [ $? = 1 ]
tap_ok $? "$t: rdr ip6 removed"


sjail destroy j01 >/dev/null ||suicide

tap_end
