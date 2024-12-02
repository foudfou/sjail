#!/bin/sh

cleanup() {
    jail -r alcatraz || true
    zfs destroy ${zfs_dataset}/jails/alcatraz || true
    rm -fr ${zfs_mount}/recipes/* || true
    echo "Done cleanup ... quitting."
    exit 1
}

test_apply_cmd() {
    local t=test_apply_cmd

    sjail create alcatraz 14.1-RELEASE ip4=10.1.1.11 >/dev/null ||suicide
    jail -c alcatraz >/dev/null ||suicide

    mkdir "${zfs_mount}/recipes/test1" ||suicide
    cat <<EOF > "${zfs_mount}/recipes/test1/Recipe"
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
    rm -fr ${zfs_mount}/recipes/* ||suicide

    ok $t
}
test_apply_cmd
