#!/bin/sh

cleanup() {
    jail -r alcatraz || true
    zfs destroy ${zfs_pool}/jails/alcatraz || true
    echo "Done cleanup ... quitting."
    exit 1
}

test_start_stop() {
    local t=test_start_stop

    sjail create alcatraz 14.1-RELEASE ip4=10.1.1.11 ip6=fd10::11 >/dev/null ||suicide

    # --- Start ---

    jail -c alcatraz >/dev/null ||suicide

    if ! jls -j alcatraz >/dev/null 2>&1; then
        fail "$t: jail not running"
    fi

    local pf_table=$(pfctl -q -t jails -T show)
    if ! (echo -e "${pf_table}" | grep -q 10.1.1.11); then
        fail "$t: pf table missing jail ip4 entry"
    fi
    if ! (echo -e "${pf_table}" | grep -q fd10::11 ); then
        fail "$t: pf table missing jail ip6 entry"
    fi

    local ok=$(sjail destroy alcatraz 2>&1 || true)
    if ! (echo $ok | grep -q "jail running");then
        fail "$t: runnin jail destroyed"
    fi

    # --- Stop ---

    jail -r alcatraz >/dev/null

    if jls -j alcatraz >/dev/null 2>&1; then
        fail "$t: jail still running"
    fi

    pf_table=$(pfctl -q -t jails -T show)
    if (echo -e "${pf_table}" | grep -q 10.1.1.11); then
        fail "$t: pf table still has jail ip4 entry"
    fi
    if (echo -e "${pf_table}" | grep -q fd10::11 ); then
        fail "$t: pf table still has jail ip6 entry"
    fi

    sjail destroy alcatraz >/dev/null

    ok $t
}
test_start_stop
