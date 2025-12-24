#!/bin/sh
. t/pre.sh

cleanup() {
    jail -r j01 || true
    zfs destroy "${zfs_dataset}/jails/j01" || true
    rm -fr ${zfs_mount}/recipes/* || true
    tap_fail "unexpected error... cleaned up"
    exit 1
}

t="apply cp"

sjail create j01 "${release}" ip4=10.1.1.11/24 >/dev/null ||suicide
jail -c j01 >/dev/null ||suicide

recipe_path="${zfs_mount}/recipes/test1"
mkdir -p "${recipe_path}/etc/foo.conf.d"
touch "${recipe_path}/etc/foo.conf.d/foo.conf"

mkdir -p "${recipe_path}/usr/local/etc"
touch "${recipe_path}/usr/local/etc/bar.conf"
chown operator "${recipe_path}/usr/local/etc/bar.conf"

cat <<EOF > "${recipe_path}/apply.sh"
# OVERLAY style
CP etc
CP usr/local/etc/bar.conf usr/local/etc
EOF


sjail apply j01 test1 >/dev/null ||suicide


jail_root="${zfs_mount}/jails/j01/root"
[ -f "${jail_root}/etc/foo.conf.d/foo.conf" ]
tap_ok $? "$t: recursive relative"

dst="${jail_root}/usr/local/etc/bar.conf"
[ -f "${dst}" ]
tap_ok $? "$t: single relative"

src="${recipe_path}/usr/local/etc/bar.conf"
stat_src=$(stat -f '%Op %Su %Sg' "${src}")
stat_dst=$(stat -f '%Op %Su %Sg' "${dst}")
tap_cmp "${stat_src}" "${stat_dst}" "$t: file stats cmp"



jail -r j01 >/dev/null ||suicide
sjail destroy j01 >/dev/null ||suicide
rm -fr ${zfs_mount}/recipes/* ||suicide

tap_end
