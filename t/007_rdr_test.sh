#!/bin/sh

cleanup() {
    jail -r alcatraz || true
    zfs destroy ${zfs_pool}/jails/alcatraz || true
    echo "Done cleanup ... quitting."
    exit 1
}

test_rdr() {
    local t=test_rdr

    sjail create alcatraz 14.1-RELEASE ip4=10.1.1.11 ip6=fd10::11 >/dev/null ||suicide
    echo -e "tcp 1234 5555\nudp 4321 9876" > "${zfs_mount}/jails/alcatraz/rdr.conf"

    # --- Start ---

    jail -c alcatraz >/dev/null ||suicide

    local rdr=$(pfctl -a "rdr/alcatraz" -Psn 2> /dev/null)
    if ! (echo -e "${rdr}" | grep -q -E ' inet .* 1234 -> 10.1.1.11 port 5555'); then
        fail "$t: pf rdr ip4 rule missing"
    fi
    if ! (echo -e "${rdr}" | grep -q  ' inet6 .* 1234 -> fd10::11 port 5555'); then
        fail "$t: pf rdr ip6 rule missing"
    fi

    # --- Stop ---

    jail -r alcatraz >/dev/null 2>&1 ||suicide

    rdr=$(pfctl -a "rdr/alcatraz" -Psn 2> /dev/null)
    if (echo -e "${rdr}" | grep -q -E ' inet .* 1234 -> 10.1.1.11 port 5555'); then
        fail "$t: pf rdr ip4 rule not removed"
    fi
    if (echo -e "${rdr}" | grep -q  ' inet6 .* 1234 -> fd10::11 port 5555'); then
        fail "$t: pf rdr ip6 rule not removed"
    fi

    sjail destroy alcatraz >/dev/null ||suicide

    ok $t
}
test_rdr
