# Integration testing

Integration testing are executed **on the developer machine**.

Integration tests drive FreeBSD VMs setup prior. `vm-bhyve` is recommended (`vm
snapshot` and `vm clone`).

VMs requirements:

- ZFS enabled
- root ssh enabled
- sjail initialized once and release created (consistent with [t/integration/pre.sh](./t/integration/pre.sh))

## Usage

Review global variables in [pre.sh](./pre.sh).

Then

```
prove t/integration/*_test.sh

# Or run individual tests
t/integration/001_networkgin_shared_interface_test.sh
```

No makefile target is provided as the developer environment could be different
than FreeBSD.
