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
zfs list -r -t snapshot tank/vm
vm clone tank/vm/sjail-test@2025-01-16-22:10:46 sjail-test1
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
