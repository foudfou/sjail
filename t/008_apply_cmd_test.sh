#!/bin/sh

cleanup() {
    jail -r alcatraz || true
    zfs destroy ${zfs_pool}/jails/alcatraz || true
    rm ${zfs_mount}/templates/*
    echo "Done cleanup ... quitting."
    exit 1
}

test_apply_cmd() {
    local t=test_apply_cmd

    sjail create alcatraz 14.1-RELEASE ip4=10.1.1.11 >/dev/null ||suicide
    jail -c alcatraz >/dev/null ||suicide

    cat <<EOF > "${zfs_mount}/templates/test1"
foo=\${foo:-53}
bar=\${bar:-0}
buz=\${buz:-no}
CMD echo foo=\${foo} bar=\${bar} buz=\${buz}
CMD id
CMD hostname
EOF

    local out=$(sjail apply alcatraz test1 ||suicide)

    local want
    for want in \
        'foo=53 bar=0 buz=no' \
        'uid=0(root) gid=0(wheel) groups=0(wheel)' \
        'alcatraz'
    do
        if ! (echo -e "${out}" | grep -q "${want}"); then
            fail "$t: incorrect or missing output: ${want}"
        fi
    done

    jail -r alcatraz >/dev/null ||suicide
    sjail destroy alcatraz >/dev/null ||suicide
    rm ${zfs_mount}/templates/*

    ok $t
}
test_apply_cmd
