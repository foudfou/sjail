#!/bin/sh
. t/pre.sh

cleanup() {
    jail -r j01 || true
    zfs destroy ${zfs_dataset}/jails/j01 || true
    rm -fr ${zfs_mount}/recipes/* || true
    tap_fail "unexpected error... cleaned up"
    exit 1
}

t="apply include"

sjail create j01 "${release}" >/dev/null ||suicide
jail -c j01 >/dev/null ||suicide



# Testing CP specifically because it needs an accurate recipe_path.
mkdir "${zfs_mount}/recipes/test1" ||suicide
touch "${zfs_mount}/recipes/test1/foo.conf"
cat <<EOF > "${zfs_mount}/recipes/test1/apply.sh"
echo recipe_path=\${recipe_path} # test1
CP foo.conf etc
echo recipe_path=\${recipe_path} # test1
EOF

mkdir "${zfs_mount}/recipes/test2" ||suicide
touch "${zfs_mount}/recipes/test2/bar.conf"
cat <<EOF > "${zfs_mount}/recipes/test2/apply.sh"
echo recipe_path=\${recipe_path} # test2
INCLUDE test1
CP bar.conf etc
echo recipe_path=\${recipe_path} # test2
EOF

mkdir "${zfs_mount}/recipes/test3" ||suicide
cat <<EOF > "${zfs_mount}/recipes/test3/apply.sh"
echo recipe_path=\${recipe_path} # test3
INCLUDE test2
echo recipe_path=\${recipe_path} # test3
EOF

out=$(sjail apply j01 test3 ||suicide)

got=$(echo -n "${out}" | grep "recipe_path=")
want="recipe_path=${zfs_mount}/recipes/test3/apply.sh
recipe_path=${zfs_mount}/recipes/test2/apply.sh
recipe_path=${zfs_mount}/recipes/test1/apply.sh
recipe_path=${zfs_mount}/recipes/test1/apply.sh
recipe_path=${zfs_mount}/recipes/test2/apply.sh
recipe_path=${zfs_mount}/recipes/test3/apply.sh"

tap_cmp "${got}" "${want}" "$t: nested"

jail_path="${zfs_mount}/jails/j01"
[ -f "${jail_path}/root/etc/foo.conf" -a \
  -f "${jail_path}/root/etc/bar.conf" ]
tap_ok $? "$t: correct cp"


jail -r j01 >/dev/null ||suicide
sjail destroy j01 >/dev/null ||suicide
rm -fr ${zfs_mount}/recipes/* ||suicide

tap_end
