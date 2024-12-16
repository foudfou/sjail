#!/bin/sh
. t/pre.sh

cleanup() {
    jail -r j01 || true
    zfs destroy ${zfs_dataset}/jails/j01 || true
    rm -fr ${zfs_mount}/recipes/* || true
    tap_fail "unexpected error... cleaned up"
    exit 1
}

t="apply cmd sh"

sjail create j01 "${release}" >/dev/null ||suicide
jail -c j01 >/dev/null ||suicide



# Testing CP specifically because it needs an accurate recipe_path.
mkdir "${zfs_mount}/recipes/test1" ||suicide
cat <<EOF > "${zfs_mount}/recipes/test1/apply.sh"
CMD var1=1 var2=2 /tmp/postinstall.sh
CMD "echo DONE > /.done"
EOF
cat <<EOF > "${zfs_mount}/jails/j01/root/tmp/postinstall.sh"
#!/bin/sh
[ -n "\$var1" ] && echo "got var1!"
[ -n "\$var2" ] && echo "got var2!"
true # don't fail caller
EOF
chmod +x "${zfs_mount}/jails/j01/root/tmp/postinstall.sh"

out=$(sjail apply j01 test1 ||suicide)

for want in \
    'got var1' \
    'got var2'
do
    echo -e "${out}" | grep -q "${want}"
    tap_ok $? "$t: cmd env vars: ${want}"
done

cat "${zfs_mount}/jails/j01/root/.done" | grep -q "DONE"
tap_ok $? "$t: cmd env redirection"


jail -r j01 >/dev/null ||suicide
sjail destroy j01 >/dev/null ||suicide
rm -fr ${zfs_mount}/recipes/* ||suicide

tap_end
