#!/bin/sh
. t/pre.sh

cleanup() {
    jail -r j01 || true
    zfs destroy "${zfs_dataset}/jails/j01" || true
    rm -fr ${zfs_mount}/recipes/* || true
    tap_fail "unexpected error... cleaned up"
    exit 1
}

t="apply mount"

sjail create j01 "${release}" ip4=10.1.1.11/24 >/dev/null ||suicide
jail -c j01 >/dev/null ||suicide

mkdir "${zfs_mount}/recipes/test1" ||suicide
cat <<EOF > "${zfs_mount}/recipes/test1/apply.sh"
MOUNT /usr/local/etc mnt/etc nullfs ro 0 0
EOF

sjail apply j01 test1 >/dev/null ||suicide


# grep fstab
dst="${zfs_mount}/jails/j01/root/mnt/etc"
line="/usr/local/etc ${dst} nullfs ro 0 0"
grep -qE '^'"${line}"'$' "${zfs_mount}/jails/j01/fstab"
tap_ok $? "$t: fstab updated"

# check mounted
mount | grep -qw "${dst}"
tap_ok $? "$t: mounted"


jail -r j01 >/dev/null ||suicide
sjail destroy j01 >/dev/null ||suicide
rm -fr ${zfs_mount}/recipes/* ||suicide

tap_end
