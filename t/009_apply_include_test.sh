#!/bin/sh

cleanup() {
    jail -r alcatraz || true
    zfs destroy ${zfs_dataset}/jails/alcatraz || true
    rm -fr ${zfs_mount}/recipes/* || true
    echo "Done cleanup ... quitting."
    exit 1
}

test_apply_include() {
    local t=test_apply_include

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

    mkdir "${zfs_mount}/recipes/test2" ||suicide
    cat <<EOF > "${zfs_mount}/recipes/test2/Recipe"
INCLUDE test1 foo=yes bar=1.34
CMD sh -c 'echo i am g\$USER'
EOF

    local out=$(sjail apply alcatraz test2 ||suicide)

    local want
    for want in \
        'foo=yes bar=1.34 buz=no' \
        'uid=0(root) gid=0(wheel) groups=0(wheel)' \
        'alcatraz' \
        'i am groot'
    do
        if ! (echo -e "${out}" | grep -q "${want}"); then
            fail "$t: incorrect or missing output: ${want}"
        fi
    done


    cat <<EOF > "${zfs_mount}/recipes/test2/Recipe"
INCLUDE test1 foo=yes badarg
EOF

    local out=$(sjail apply alcatraz test2 2>&1)

    local want='invalid format: badarg'
    if ! (echo -e "${out}" | grep -q "${want}"); then
        fail "$t: error not detected: ${want}"
    fi

    jail -r alcatraz >/dev/null ||suicide
    sjail destroy alcatraz >/dev/null ||suicide
    rm -fr ${zfs_mount}/recipes/* ||suicide

    ok $t
}
test_apply_include
