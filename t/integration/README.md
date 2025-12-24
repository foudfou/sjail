# Integration testing

Integration tests are executed **on the developer machine** and drive FreeBSD
VMs. These must be setup prior.

VMs requirements:

- ZFS enabled
- root ssh enabled
- sjail initialized once and release created (consistent with [t/integration/pre.sh](./t/integration/pre.sh))

The general scenario is spawning jails in vm1 and checking connectivity from vm2.

## VM setup

If you already have a running FreeBSD vm, you can just clone it:

```
zfs list -r -t snapshot tank/vm
vm clone sjail-test@2025-01-16-22:10:46 sjail-test1
vm clone sjail-test@2025-01-16-22:10:46 sjail-test2
```

## Usage

Review global variables in [pre.sh](./pre.sh), configure VMs networking
accordingly and start them.

Then

```
prove t/integration/*_test.sh

# Or run individual tests
t/integration/001_networking_shared_interface_test.sh
```

TODO automate tests / CI
