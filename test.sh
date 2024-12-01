#!/bin/sh
set -eu

. /usr/local/etc/sjail.conf

trap cleanup 0 1 2 3 6 15
cleanup() {
    if [ $nocleanup != 1 ]; then
        zfs destroy -r ${zfs_pool} || true
        mv /usr/local/etc/sjail.conf.orig /usr/local/etc/sjail.conf
    fi
    zfs destroy ${zfs_pool}/jails/alcatraz 2>/dev/null || true
    echo "Done cleanup ... quitting."
}

nocleanup=0
reuse=0
if [ $# -gt 0 ]; then
    opt=${1}; shift
    case $opt in
        nocleanup)
            nocleanup=1
            ;;
        reuse)
            nocleanup=1
            reuse=1
            ;;
        clean)
            nocleanup=0
            cleanup
            exit 0
            ;;
        *)
            ;;
    esac
fi

cp -n /usr/local/etc/sjail.conf /usr/local/etc/sjail.conf.orig || true

cat <<EOF > /usr/local/etc/sjail.conf
zfs_pool="zroot/testsjails"
zfs_mount="/testsjails"
loopback="lo1"
pf_ext_if="vpn_cli_if"
EOF

fail() {
    echo "❌ $1"
    exit 1
}
ok() {
    echo "✔ $1"
}

test_init() {
    local t=test_init

    sjail init

    if ! zfs list -H ${zfs_pool} >/dev/null;then
        fail "$t: missing zpool"
    fi

    if ! zfs list -H ${zfs_pool}/templates >/dev/null;then
        fail "$t: missing template zpool"
    fi

    # FIXME how do we not mess with main /etc/jail.conf? vm?
    if ! grep -q '.include "'${zfs_mount}/jails /etc/jail.conf;then
        fail "$t: missing .include in /etc/jails.conf"
    fi

    if ! sysrc -c jail_enable="YES";then
        fail "$t: incorrect sysrc jail_enable"
    fi

    if ! sysrc -c cloned_interfaces+="${loopback}";then
        fail "$t: missing sysrc cloned_interfaces"
    fi

    ok $t
}
[ $reuse == 1 ] || test_init

test_fetch() {
    local t=test_fetch

    sjail fetch 14.1-RELEASE

    if [ ! -e ${zfs_mount}/releases/14.1-RELEASE/COPYRIGHT ]; then
        fail "$t: release fetch incomplete"
    fi

    ok $t
}
[ $reuse == 1 ] || test_fetch

test_create() {
    local t=test_create

    sjail create alcatraz 14.1-RELEASE >/dev/null

    if ! zfs list -H ${zfs_pool}/jails/alcatraz >/dev/null;then
        fail "$t: missing jail alcatraz"
    fi

    if [ ! -d ${zfs_mount}/jails/alcatraz ]; then
        fail "$t: jail not mounted"
    fi

    local jail_path="${zfs_mount}/jails/alcatraz"
    if [ ! -e ${jail_path}/fstab -o \
         ! -e ${jail_path}/root -o \
         ! -e ${jail_path}/jail.conf ]; then
        fail "$t: missing jail files"
    fi

    # sysrc -c doesn't seem to work well for lists
    if ! $(sysrc jail_list | grep -qw alcatraz);then
        fail "$t: missing sysrc jail_list entry"
    fi

    zfs destroy ${zfs_pool}/jails/alcatraz

    ok $t
}
test_create

test_destroy() {
    local t=test_destroy

    sjail create alcatraz 14.1-RELEASE >/dev/null
    sjail destroy alcatraz

    if zfs list -H ${zfs_pool}/jails/alcatraz 2>/dev/null;then
        fail "$t: jail pool not destroyed"
    fi

    if $(sysrc jail_list | grep -qw alcatraz);then
        fail "$t: jail not removed from jail_list entry"
    fi

    ok $t
}
test_destroy

test_create_jail_conf() {
    local t=test_create_jail_conf

    local jail_conf="${zfs_mount}/jails/alcatraz/jail.conf"

    sjail create alcatraz 14.1-RELEASE >/dev/null
    if grep -q addr ${jail_conf};then
        fail "$t: unexpected parameter in jail.conf"
    fi
    sjail destroy alcatraz

    sjail create alcatraz 14.1-RELEASE ip4=1.2.3.4 >/dev/null
    if ! grep -q "ip4.addr = 1.2.3.4;" ${jail_conf};then
        fail "$t: missing parameter ip4.addr in jail.conf"
    fi
    sjail destroy alcatraz

    sjail create alcatraz 14.1-RELEASE ip6=fd10::1 >/dev/null
    if ! grep -q "ip6.addr = fd10::1;" ${jail_conf};then
        fail "$t: missing parameter ip6.addr in jail.conf"
    fi
    sjail destroy alcatraz

    sjail create alcatraz 14.1-RELEASE ip4=1.2.3.4 ip6=fd10::1 >/dev/null
    if ! (grep -q "ip6.addr = fd10::1;" ${jail_conf} && \
              grep -q "ip4.addr = 1.2.3.4;" ${jail_conf});then
        fail "$t: missing parameter ipx.addr in jail.conf"
    fi
    sjail destroy alcatraz

    ok $t
}
test_create_jail_conf

test_start_stop() {
    local t=test_start_stop

    sjail create alcatraz 14.1-RELEASE ip4=10.1.1.11 >/dev/null
    jail -c alcatraz >/dev/null

    if ! jls -j alcatraz >/dev/null 2>&1; then
        fail "$t: jail not running"
    fi

    local ok=$(sjail destroy alcatraz 2>&1 || true)
    if ! (echo $ok | grep -q "jail running");then
        fail "$t: runnin jail destroyed"
    fi

    jail -r alcatraz >/dev/null
    if jls -j alcatraz >/dev/null 2>&1; then
        fail "$t: jail still running"
    fi

    sjail destroy alcatraz

    ok $t
}
test_start_stop
