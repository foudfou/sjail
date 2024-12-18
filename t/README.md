# Unit testing

Unit testing must be done inside an isolated environment. Easiest is to setup a
FreeBSD vm with `vm-bhyve`.

## Usage

```
cat <<EOF > /usr/local/etc/sjail.conf
zfs_dataset="zroot/sjail"
zfs_mount="/jails"
interface="lo1"
pf_ext_if="ext_if"
EOF
make install
sysrc cloned_interfaces+="lo1"
service netif cloneup
sjail init
```

Note we're intentionally focusing on the cloned loopback network setup as it's
more involved than the shared interface.

Then

```
make test
```

Or run individual tests:

```
t/001_init_test.sh
t/002_release_create_test.sh
```

Note you can set `nofetch=1` in `t/002_release_create_test.sh` when repeating
the whole suite. This will skip the download of the FreeBSD base image and use
the one in `/tmp`.

Reset with

```
zfs destroy -r zroot/sjail
sysrc jail_list=""
```

## Development

* Watch out for escaping `$` in string definitions:

  ```
  cat <<EOF > "${zfs_mount}/jails/j01/root/tmp/postinstall.sh"
  #!/bin/sh
  [ -n "\$var1" ] && echo "got var1!"
  true # don't fail caller
  EOF
 ```
