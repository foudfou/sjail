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

sjail create alcatraz "${release}" ip4=10.1.1.11/24 >/dev/null ||suicide
jail -c alcatraz >/dev/null ||suicide

# --- Happy path ---

mkdir "${zfs_mount}/recipes/test1" ||suicide
cat <<EOF > "${zfs_mount}/recipes/test1/apply.sh"
foo=\${foo:-53}
bar=\${bar:-0}
buz=\${buz:-no}
CMD echo foo=\${foo} bar=\${bar} buz=\${buz}
CMD id
CMD hostname
EOF

mkdir "${zfs_mount}/recipes/test2" ||suicide
cat <<EOF > "${zfs_mount}/recipes/test2/apply.sh"
INCLUDE test1 foo=yes bar=1.34
echo recipe_path=\${recipe_path} # test2
CMD echo i am g\$USER
# Nested shell is tricky because of quote escaping.
#CMD sh -c 'echo i am g\$USER'
jexec -l \${jail_name} sh -c 'echo toor\\\\$HOME'
EOF

out=$(sjail apply alcatraz test2 ||suicide)

for want in \
    'foo=yes bar=1.34 buz=no' \
    'uid=0(root) gid=0(wheel) groups=0(wheel)' \
    'alcatraz' \
    'i am groot' \
    'toor\\/root'
do
    echo -e "${out}" | grep -q "${want}"
    tap_ok $? "$t: include success: ${want}"
done


# --- Bad arg ---

cat <<EOF > "${zfs_mount}/recipes/test2/apply.sh"
INCLUDE test1 foo=yes badarg
EOF

out=$(sjail apply alcatraz test2 2>&1 ||true)

want='invalid format: badarg'
echo -e "${out}" | grep -q "${want}"
tap_ok $? "$t: bad argument format: ${want}"


jail -r alcatraz >/dev/null ||suicide
sjail destroy alcatraz >/dev/null ||suicide
rm -fr ${zfs_mount}/recipes/* ||suicide

tap_end
