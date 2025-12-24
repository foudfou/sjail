#!/bin/sh
. t/pre.sh

cleanup() {
    jail -r j01 || true
    zfs destroy "${zfs_dataset}/jails/j01" || true
    rm -fr ${zfs_mount}/recipes/* || true
    tap_fail "unexpected error... cleaned up"
    exit 1
}

t="apply sysrc service"

sjail create j01 "${release}" ip4=10.1.1.11/24 >/dev/null ||suicide
jail -c j01 >/dev/null ||suicide

mkdir "${zfs_mount}/recipes/test1" ||suicide
cat <<EOF > "${zfs_mount}/recipes/test1/apply.sh"
# Picking up inetd so as to avoid pkg install. Hope it's not deprecated.
SYSRC inetd_enable="YES"
SERVICE inetd start
EOF

out=$(sjail apply j01 test1 ||suicide)
for pat in \
  '^inetd_enable: NO -> YES$' \
  '\bStarting inetd.$'; do
    echo -e "${out}" | grep -qE "${pat}"
    tap_ok $? "$t: apply success: ${pat}"
done

sysrc -j j01 -c inetd_enable="YES"
tap_ok $? "$t: sysrc success"

jexec -l j01 service inetd status | grep -qE '^inetd is running as pid '
tap_ok $? "$t: service running"


jail -r j01 >/dev/null ||suicide
sjail destroy j01 >/dev/null ||suicide
rm -fr ${zfs_mount}/recipes/* ||suicide

tap_end
