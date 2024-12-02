#!/bin/sh
. t/pre.sh

cleanup() {
    jail -r alcatraz || true
    zfs destroy ${zfs_dataset}/jails/alcatraz || true
    rm -fr ${zfs_mount}/recipes/* || true
    tap_fail "unexpected error... cleaned up"
    exit 1
}

t="apply include"

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

mkdir "${zfs_mount}/recipes/test2" ||suicide
cat <<EOF > "${zfs_mount}/recipes/test2/Recipe"
INCLUDE test1 foo=yes bar=1.34
CMD sh -c 'echo i am g\$USER'
EOF

out=$(sjail apply alcatraz test2 ||suicide)

for want in \
    'foo=yes bar=1.34 buz=no' \
        'uid=0(root) gid=0(wheel) groups=0(wheel)' \
        'alcatraz' \
        'i am groot'
do
    if ! (echo -e "${out}" | grep -q "${want}"); then
        tap_fail "$t: include success: ${want}"
    fi
    tap_pass "$t: include success"
done


cat <<EOF > "${zfs_mount}/recipes/test2/Recipe"
INCLUDE test1 foo=yes badarg
EOF

out=$(sjail apply alcatraz test2 2>&1 ||true)

want='invalid format: badarg'
if ! (echo -e "${out}" | grep -q "${want}"); then
    tap_fail "$t: bad argument format: ${want}"
fi
tap_pass "$t: bad argument format"

jail -r alcatraz >/dev/null ||suicide
sjail destroy alcatraz >/dev/null ||suicide
rm -fr ${zfs_mount}/recipes/* ||suicide

tap_end
