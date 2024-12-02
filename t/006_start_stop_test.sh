#!/bin/sh
. t/pre.sh

cleanup() {
    jail -r alcatraz || true
    zfs destroy ${zfs_dataset}/jails/alcatraz || true
    tap_fail "unexpected error... cleaned up"
    exit 1
}

t="start stop"

sjail create alcatraz "${release}" ip4=10.1.1.11 ip6=fd10::11 >/dev/null ||suicide

# --- Start ---

jail -c alcatraz >/dev/null ||suicide

if ! jls -j alcatraz >/dev/null 2>&1; then
    tap_fail "$t: jail running"
fi
tap_pass "$t: jail running"

pf_table=$(pfctl -q -t jails -T show)
if ! (echo -e "${pf_table}" | grep -q 10.1.1.11); then
    tap_fail "$t: pf table ip4 entry"
fi
tap_pass "$t: pf table ip4 entry"
if ! (echo -e "${pf_table}" | grep -q fd10::11 ); then
    tap_fail "$t: pf table ip6 entry"
fi
tap_pass "$t: pf table ip6 entry"

ok=$(sjail destroy alcatraz 2>&1 || true)
if ! (echo $ok | grep -q "jail running");then
    tap_fail "$t: running jail not destroyed"
fi
tap_pass "$t: running jail not destroyed"

# --- Stop ---

jail -r alcatraz >/dev/null

if jls -j alcatraz >/dev/null 2>&1; then
    tap_fail "$t: jail still running"
fi

pf_table=$(pfctl -q -t jails -T show)
if (echo -e "${pf_table}" | grep -q 10.1.1.11); then
    tap_fail "$t: pf table ip4 entry removed"
fi
tap_pass "$t: pf table ip4 entry removed"
if (echo -e "${pf_table}" | grep -q fd10::11 ); then
    tap_pass "$t: pf table ip4 entry removed"
fi
tap_pass "$t: pf table ip6 entry removed"

sjail destroy alcatraz >/dev/null

tap_end
