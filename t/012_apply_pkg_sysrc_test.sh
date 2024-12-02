#!/bin/sh
. t/pre.sh

cleanup() {
    jail -r j01 || true
    zfs unmount -f ${zfs_mount}/jails/j01 || true
    zfs destroy "${zfs_dataset}/jails/j01" || true
    rm -fr ${zfs_mount}/recipes/* || true
    tap_fail "unexpected error... cleaned up"
    exit 1
}

t="apply pkg sysrc"

sjail create j01 "${release}" ip4=10.1.1.11 >/dev/null ||suicide
jail -c j01 >/dev/null ||suicide

mkdir "${zfs_mount}/recipes/test1" ||suicide
cat <<EOF > "${zfs_mount}/recipes/test1/Recipe"
PKG htop tree
SYSRC foo_enable="YES"
EOF

out=$(sjail apply j01 test1 ||suicide)
echo -e "$out" > /tmp/out1
for pat in '^foo_enable:  -> YES$' \
  '\bExtracting htop-.*: .*done$' \
  '\bExtracting tree-.*: .*done$' \
  '^j01: created$'; do
    echo -e "${out}" | grep -qE "${pat}"
    tap_ok $? "$t: pkg success: ${pat}"
done

for pkg in htop tree; do
    jexec -l j01 pkg info -e "${pkg}"
    tap_ok $? "$t: pkg installed: ${pkg}"
done

sysrc -j j01 -c foo_enable="YES"
tap_ok $? "$t: sysrc success"


jail -r j01 >/dev/null ||suicide
# Can't destroy dataset immediately after stopping jail.
zfs unmount -f ${zfs_mount}/jails/j01
sjail destroy j01 >/dev/null ||suicide
rm -fr ${zfs_mount}/recipes/* ||suicide

tap_end
