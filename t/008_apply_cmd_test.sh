#!/bin/sh
. t/pre.sh

cleanup() {
    jail -r alcatraz || true
    zfs destroy ${zfs_dataset}/jails/alcatraz || true
    rm -fr ${zfs_mount}/recipes/* || true
    tap_fail "unexpected error... cleaned up"
    exit 1
}

t="apply cmd"

sjail create alcatraz "${release}" ip4=10.1.1.11 >/dev/null ||suicide
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

out=$(sjail apply alcatraz test1 ||suicide)

for want in \
    'foo=53 bar=0 buz=no' \
        'uid=0(root) gid=0(wheel) groups=0(wheel)' \
        'alcatraz'
do
    echo -e "${out}" | grep -q "${want}"
    tap_ok $? "$t: cmd success: ${want}"
done

jail -r alcatraz >/dev/null ||suicide
sjail destroy alcatraz >/dev/null ||suicide
rm -fr ${zfs_mount}/recipes/* ||suicide

tap_end
