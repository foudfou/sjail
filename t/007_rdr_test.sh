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
echo -e "tcp 1234 5555\nudp 4321 9876" > "${zfs_mount}/jails/alcatraz/rdr.conf"

# --- Start ---

jail -c alcatraz >/dev/null ||suicide

rdr=$(pfctl -a "rdr/alcatraz" -Psn 2> /dev/null)
if ! (echo -e "${rdr}" | grep -q -E ' inet .* 1234 -> 10.1.1.11 port 5555'); then
    tap_fail "$t: rdr ip4"
fi
tap_pass "$t: rdr ip4"
if ! (echo -e "${rdr}" | grep -q  ' inet6 .* 1234 -> fd10::11 port 5555'); then
    tap_fail "$t: rdr ip6"
fi
tap_pass "$t: rdr ip6"

# --- Stop ---

jail -r alcatraz >/dev/null 2>&1 ||suicide

rdr=$(pfctl -a "rdr/alcatraz" -Psn 2> /dev/null)
if (echo -e "${rdr}" | grep -q -E ' inet .* 1234 -> 10.1.1.11 port 5555'); then
    tap_fail "$t: rdr ip4 rule removed"
fi
tap_pass "$t: rdr ip4 rule removed"
if (echo -e "${rdr}" | grep -q  ' inet6 .* 1234 -> fd10::11 port 5555'); then
    tap_fail "$t: rdr ip6 rule removed"
fi
tap_pass "$t: rdr ip6 rule removed"

sjail destroy alcatraz >/dev/null ||suicide

tap_end
