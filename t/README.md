# Unit testing

Unit testing must be done inside an isolated environment. Easiest is to setup a
FreeBSD vm with `vm-bhyve`.

## Usage

### Create vm

See [quick start instructions](https://github.com/churchers/vm-bhyve/) to setup
vm-bhyve, then:

```
pkg install qemu-tools
# vm img supports .raw .qcow2
vm img https://download.freebsd.org/releases/VM-IMAGES/14.3-RELEASE/amd64/Latest/FreeBSD-14.3-RELEASE-amd64-zfs.qcow2.xz
vm create -t freebsd-zvol -i FreeBSD-14.3-RELEASE-amd64-zfs.qcow2 sjail-test
vm start sjail-test
vm console sjail-test # login: root no password

echo nameserver 192.168.1.1 > /etc/resolv.conf
cp /usr/share/zoneinfo/Europe/Berlin /etc/localtime

# in the console
passwd

cat <<EOF > /etc/rc.conf
hostname="sjail-test"
ifconfig_vtnet0="inet 192.168.1.201 netmask 255.255.255.0"
defaultrouter="192.168.1.1"
sshd_enable="YES"
zfs_enable="YES"
pf_enable="YES"
cloned_interfaces="lo1 bridge0"
ifconfig_bridge0="addm em0 up"
EOF
service netif restart

sed -i -e 's/^#PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config
ssh-keygen -A
service sshd restart

mkdir /root/.ssh
chmod 755 /root/.ssh
echo "YOUR_SSH_PUB_KEY" > /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

mkdir -p /usr/local/etc
cat <<EOF >/usr/local/etc/sjail.conf
zfs_dataset="zroot/sjail"
zfs_mount="/sjail"
interface="lo1"
pf_ext_if="ext_if"
EOF

cat <<EOF >/etc/pf.conf
ext_if=vtnet0
icmp_types  = "{ echoreq, unreach }"
icmp6_types = "{ echoreq, unreach, routeradv, neighbrsol, neighbradv }"

# sjail-managed
table <jails> persist

set skip on lo

# actually not used
rdr-anchor "rdr/*"

nat on \$ext_if from <jails> to any -> (\$ext_if:0)

block in all
pass out all keep state
antispoof for \$ext_if

pass inet proto icmp icmp-type \$icmp_types
pass inet6 proto icmp6 icmp6-type \$icmp6_types

# Allow ssh
pass in inet proto tcp from any to any port ssh flags S/SA keep state
EOF

pkg install perl5

mkdir sjail
# copy sjail code over to sjail/
make -C sjail install
sjail init

~ CTRL-D

# back on host
vm snapshot sjail-test
```

### Run tests

Note we're intentionally focusing on the cloned loopback network setup as it's
more involved than the shared interface.

Review `t/pre.sh` then

```
make test-unit
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
