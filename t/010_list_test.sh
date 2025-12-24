#!/bin/sh
. t/pre.sh

cleanup() {
    rm -f /etc/jail.sjail_unmanaged.conf
    for j in ${jails} mail smail; do
        jail -r "${j}" >/dev/null ||true
        zfs destroy "${zfs_dataset}/jails/${j}" || true
    done
    tap_fail "unexpected error... cleaned up"
    exit 1
}

t="list"

jails="j01 j02 j03 j04"

for j in ${jails}; do
    sjail create "${j}" "${release}" "ip4=10.1.1.2${j#j}/24" >/dev/null ||suicide
done

include='.include "/etc/jail.*.conf";'
if ! grep -q "${include}" /etc/jail.conf; then
    echo "${include}" >> /etc/jail.conf
fi

cat <<EOF > /etc/jail.sjail_unmanaged.conf
sjail_unmanaged {
  host.hostname = sjail_unmanaged;
  ip4.addr = 10.1.1.205;
}
EOF

list=$(sjail list)
for j in ${jails}; do
    echo -e "${list}" | grep -qE "^${j}\s+Down\s+${release}\b"
    tap_ok $? "$t: stopped jail ${j} listed"
done

echo -e "${list}" | grep -qE "^sjail_unmanaged\s+Down\s+\-\s"
tap_ok $? "$t: unmanaged jail listed"

# --- Start ---

for j in ${jails}; do
    jail -c "${j}" >/dev/null ||suicide
done

list=$(sjail list)
for j in ${jails}; do
    echo -e "${list}" | grep -qE "^${j}\s+Up\s+${release}\b"
    tap_ok $? "$t: started jail ${j} listed"
done


rm -f /etc/jail.sjail_unmanaged.conf
for j in ${jails}; do
    jail -r "${j}" >/dev/null ||suicide
    zfs destroy "${zfs_dataset}/jails/${j}" ||suicide
done

# --- Dup, similar name/hostname ---

sjail create mail "${release}" >/dev/null ||suicide
sjail create smail "${release}" >/dev/null ||suicide

# Bug prior 2acad86 where jail name `mail` would match against `smail`'s
# hostname `mail.foo.com` in jls, thus wrongly displaying jail `mail` as Up.
sed -ie 's/\}/host.hostname = "mail.foo.com";\n}/' "${zfs_mount}/jails/smail/jail.conf"

jail -c smail >/dev/null ||suicide

list=$(sjail list)
echo -e "${list}" | grep -qE "^mail\s+Down\s+${release}\s+${zfs_mount}/jails/mail/root\b"
tap_ok $? "$t: similar names: jail mail down"
echo -e "${list}" | grep -qE "^smail\s+Up\s+${release}\s+${zfs_mount}/jails/smail/root\b"
tap_ok $? "$t: similar names: jail smail up"

jail -r smail >/dev/null ||suicide
zfs destroy "${zfs_dataset}/jails/mail" ||suicide
zfs destroy "${zfs_dataset}/jails/smail" ||suicide


tap_end
