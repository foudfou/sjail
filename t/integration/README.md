# Integration testing

Integration tests are executed **on the developer machine** and drive FreeBSD
VMs. These must be setup prior.

VMs requirements:

- ZFS enabled
- root ssh enabled
- sjail initialized once and release created (consistent with [t/integration/pre.sh](./t/integration/pre.sh))

## VM setup

If you already have a running FreeBSD vm, you can just clone it:

```
vm snapshot sjail-test
vm clone sjail-test@2024-12-17-23:02:44 sjail-test1
```

Otherwise you can create brand new ones:

```
vm img https://download.freebsd.org/releases/VM-IMAGES/14.2-RELEASE/amd64/Latest/FreeBSD-14.2-RELEASE-amd64-BASIC-CLOUDINIT.zfs.raw.xz
vm create -t freebsd-zvol -i FreeBSD-14.2-RELEASE-amd64-BASIC-CLOUDINIT.zfs.raw sjail-test1
vm start sjail-test1
vm console sjail-test1 # login: root no password

passwd

cat <<EOF > /etc/rc.conf
hostname="sjail-test1"
ifconfig_em0="inet 192.168.1.201 netmask 255.255.255.0"
defaultrouter="192.168.1.1"
sshd_enable="YES"
zfs_enable="YES"
pf_enable="YES"
cloned_interfaces="lo1"
EOF

sed -i -e 's/^#PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config
service ssh restart

mkdir /root/.ssh
chmod 755 /root/.ssh
echo "YOUR_SSH_PUB_KEY" > /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

cat <<EOF >/usr/local/etc/sjail.conf
zfs_dataset="zroot/sjail"
zfs_mount="/sjail"
interface="vtnet0"
pf_ext_if=""
EOF
```

## Usage

Review global variables in [pre.sh](./pre.sh).

Then

```
prove t/integration/*_test.sh

# Or run individual tests
t/integration/001_networking_shared_interface_test.sh
```

TODO automate tests / CI
