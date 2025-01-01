#!/bin/sh
. t/pre.sh

cleanup() {
    jail -r j01 || true
    zfs destroy "${zfs_dataset}/jails/j01" || true
    rm -fr ${zfs_mount}/recipes/* || true
    tap_fail "unexpected error... cleaned up"
    exit 1
}

t="apply conf"

sjail create j01 "${release}" ip4=10.1.1.11 >/dev/null ||suicide
jail -c j01 >/dev/null ||suicide

mkdir "${zfs_mount}/recipes/test1" ||suicide
cat <<EOF > "${zfs_mount}/recipes/test1/apply.sh"
CONF sysvshm=new
CONF allow.mlock=1;
CONF mount.devfs
CONF allow.set_hostname
EOF

out=$(sjail apply j01 test1 ||suicide)

echo -e "${out}" | grep -qE "JAIL RESTARTED"
tap_ok $? "$t: jail restarted"


# grep jail.conf
. /usr/local/share/sjail/common.sh
param=$(jail_conf j01 | jail_conf_get_val sysvshm)
tap_cmp "${param}" new "$t: get_val - sysvshm"

param=$(jail_conf j01 | jail_conf_get_val allow.mlock)
tap_cmp "${param}" 1 "$t: get_val - allow.mlock"

param=$(jail_conf j01 | jail_conf_get_bool mount.devfs)
tap_cmp "${param}" "mount.devfs" "$t: get_bool mount.devfs"

param=$(jail_conf j01 | jail_conf_get_bool allow.set_hostname)
tap_cmp "${param}" "allow.set_hostname" "$t: get_bool allow.set_hostname"

param=$(jail_conf j01 | jail_conf_get_bool allow.mount.zfs)
tap_cmp "${param}" "" "$t: unset"


jail -r j01 >/dev/null ||suicide
sjail destroy j01 >/dev/null ||suicide
rm -fr ${zfs_mount}/recipes/* ||suicide

tap_end
