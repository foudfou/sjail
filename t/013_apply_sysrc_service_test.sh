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

sjail create j01 "${release}" ip4=10.1.1.11/24 nat=1 >/dev/null ||suicide
jail -c j01 >/dev/null ||suicide

mkdir "${zfs_mount}/recipes/test1" ||suicide
cat <<EOF > "${zfs_mount}/recipes/test1/apply.sh"
# Since we use FreeBSD-set-minimal-jail, we can't pick inetd (in -optional) and
# avoid pkg (30s-1m more, possible networking issues). On the bright side we
# actually test PKG.
PKG nginx
SYSRC nginx_enable="YES"
SERVICE nginx start
EOF

out=$(sjail apply j01 test1 ||suicide)
for pat in \
  '^nginx_enable: NO -> YES$' \
  '\bStarting nginx.$'; do
    echo -e "${out}" | grep -qE "${pat}"
    tap_ok $? "$t: apply success: ${pat}"
done

sysrc -j j01 -c nginx_enable="YES"
tap_ok $? "$t: sysrc success"

jexec -l j01 service nginx status | grep -qE '^nginx is running as pid '
tap_ok $? "$t: service running"


jail -r j01 >/dev/null ||suicide
sjail destroy j01 >/dev/null ||suicide
rm -fr ${zfs_mount}/recipes/* ||suicide

tap_end
