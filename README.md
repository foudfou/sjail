# sjail

Simple thin jail management tool.

Provides:

1. a straightforward script to create/destroy jails
2. a recipe system to initialize jails, heavily inspired by [Bastille](https://github.com/BastilleBSD/bastille)

## Motivation

- Easy to understand.
- Rigid limited feature set:
  - Leverage jail(8) as much as possible;
  - ZFS thin jails only;
  - Unopiniated networking (can mix shared interface, cloned loopback and VNET);

## Usage

```
# make install
```

For loopback networking (optional):

```
# sysrc cloned_interfaces+="lo1"
# service netif cloneup
```

For VNET networking (optional):

```
# sysrc cloned_interfaces+="bridge0"
# sysrc ifconfig_bridge0="addm em0 up"  # attach to physical network
# service netif cloneup
```

Create and review `/usr/local/etc/sjail.conf`:

|               |                                                                               |
|---------------|-------------------------------------------------------------------------------|
| `zfs_dataset` | pool to store all sjail data (will be created by `sjail init`)                |
| `zfs_mount`   | mountpoint for sjail data                                                     |
| `interface`   | default interface to attach jails to.                                         |
| `ext_if`      | external interface used in pf RDR rules to forward incoming traffic to jails. |

Following commands are provided:

|                 |                                                                                           |
|-----------------|-------------------------------------------------------------------------------------------|
| Init            | `sjail init`                                                                              |
| Create release  | `sjail rel-create 14.2-RELEASE`                                                           |
| Update release  | `sjail rel-update 14.2-RELEASE`                                                           |
| Destroy release | `sjail rel-destroy 14.2-RELEASE`                                                          |
| Create jail     | `sjail create alcatraz 14.2-RELEASE ip4=192.168.1.11/24 ip6=fd10:0:0:100::11 nat=1 rdr=0` |
|                 | `sjail create alcatraz 14.2-RELEASE ip4=10.1.1.13/24 iface=lo1 nat=1 rdr=1`               |
|                 | `sjail create alcatraz 14.2-RELEASE ip4=192.168.1.12/24 vnet=1 iface=bridge0 nat=1`       |
| Destroy jail    | `sjail destroy alcatraz`                                                                  |
| List            | `jls` or `sjail list` for all                                                             |
| Start           | `jail -c alcatraz`                                                                        |
| Stop            | `jail -r alcatraz`                                                                        |
| Recipe          | `sjail apply alcatraz some/recipe`                                                        |

Compose your own:

|                    |                                                                               |
|--------------------|-------------------------------------------------------------------------------|
| forAll             | `jls name \| xargs …`                                                         |
| Pkg upgrade forAll | `jls name \| xargs -I% jexec -l % pkg upgrade -y` or just `sjail pkg-upgrade` |


## Recipes

Recipes live by convention in `${zfs_mount}/recipes`.

Recipes are directly inspired by Bastille templates[^1]. A recipe is a
directory comprised of:

1. A mandatory `apply.sh` file which contains *commands*.
2. Optional files to be deployed via the `CP` command.

`apply.sh` is a shell script[^2]. Commands are shell functions.

| Command   | Comments                                                                                        |
|-----------|-------------------------------------------------------------------------------------------------|
| `CMD`     | arguments executed inside `sh -c`. I.e. quote commands with redirects, logical operations, etc. |
| `CONF`    | **breaking compat**: name change (from `CONFIG`) + no `set` argument.                           |
| `CP`      | copies recursively                                                                              |
| `INCLUDE` |                                                                                                 |
| `MOUNT`   |                                                                                                 |
| `PKG`     |                                                                                                 |
| `EXPOSE`  | **breaking compat**: name change (from `RDR`)                                                   |
| `RESTART` | convenient in conjunction with `CONF`                                                           |
| `SERVICE` |                                                                                                 |
| `SYSRC`   |                                                                                                 |

### Compatibility with Bastille

When migrating from Bastille templates, here's a little checklist:

- Command names; see **breaking compat** in the previous table
- `ARG` is replaced with the `sh` equivalent:
  ```diff
  -ARG php_prefix=php82
  +php_prefix=${php_prefix:-php82}
  ```
- `INCLUDE` arguments are also replaced with the `sh` equivalent:
  ```diff
  -INCLUDE my/service-php --arg php_prefix=php82
  +INCLUDE my/service-php php_prefix=php82
  ```
  - Make sure to escape spaces in strings:
    ```
    INCLUDE foudfou/service-nodejs npm_global="pm2\ pnpm" # otherwise interpreted as npm_global=pm2
    ```

Optional arguments must still be defined:

```sh
maxmemory=${maxmemory:-}
maxmemory_policy=${maxmemory_policy:-}
```

## Networking

Sjail supports multiple networking setups: cloned loopback, shared interface,
VNET. You can mix them. For example cloned loopback for host-private jails,
together with shared interface for LAN-public jails.

Sjail does NOT automatically determine if NAT or RDR are needed—that's left
to the user via `nat=1` and `rdr=1` creation arguments.

The `iface` argument overrides the default `interface` configuration option and
determines which interface to attach jails to—it does NOT determine NAT or RDR
behavior.

NAT/RDR may be required in complex setups (see [custom networking](#Custom)),
but the basic guideline is:

- NAT is needed when the jail's IP is NOT routable to the outside network. In
  general this is the host network.

- RDR is only needed when 1. Jail IP is not directly routable AND 2. we want
  inbound connections to the jail.

Sjail accepts multiple addresses (e.g.
`ip4="lo1|127.0.1.2,em0|192.168.1.82/24"`
`ip4="192.168.1.81/24,192.168.1.82/24"` or dual-stack `ip4=192.168.1.81/24
ip6=fd10::81`), but **pf rules apply to ALL addresses**. For this reason,
**sjail works best with one IP per jail**. Complex multi-IP setups are not
supported.

Note the FreeBSD 10.2 Handbook section on ezjail used to mentionned:

> To keep jail loopback traffic off the host's loopback network interface lo0,
> a second loopback interface is created by adding an entry to /etc/rc.conf […]

It was indeed a common ezjail pattern to assign both a loopback IP (127.0.1.x
on lo1) and a LAN IP (192.168.1.x on em0) to each jail. VNET has largely
superseded this approach.

Bastille is also a [good source of
information](https://github.com/BastilleBSD/bastille/blob/642c78ffee70510cf3c2d9899d20e671b5bc60d2/docs/chapters/networking.rst)
for jail networking.

### Shared interface

Jails' IPs are attached to the host's external interface and are in the same
subnet:

```
# Provided host ip = 192.168.1.23/24 and interface="em0" in sjail.conf
sjail create j01 14.2-RELEASE ip4=192.168.1.201/24
```

Jails are thus accessible to the local network. No specific `pf` adaptation is
required.

### Cloned loopback

Jails' IPs are attached to a clone loopback interface (like `lo1`). Traffic
between host and jails is enabled with `pf`: outgoing via NAT, incoming via
RDR.

```
ext_if=vtnet0
icmp_types  = "{ echoreq, unreach }"
icmp6_types = "{ echoreq, unreach, routeradv, neighbrsol, neighbradv }"

# sjail-managed
table <jails> persist

set skip on lo

# sjail-managed
rdr-anchor "rdr/*"

nat on $ext_if from <jails> to any -> ($ext_if:0)

block in all
pass out all keep state
antispoof for $ext_if

pass inet proto icmp icmp-type $icmp_types
pass inet6 proto icmp6 icmp6-type $icmp6_types

# Allow ssh
pass in inet proto tcp from any to any port ssh flags S/SA keep state
```

Port forwarding is persisted to `${jail_path}/rdr.conf` as lines of the format
`<proto> <host_port> <client_port>`. They are applied *for ip4 and ip6* via
`pf` rdr rules on jail start and cleared on jail stop.

<!-- FIXME rename EXPOSE to RDR -->
`rdr.conf` can be created manually of via the recipe `EXPOSE` command.

### VNET

Jails' IPs are attached to user-provided bridge. **Sjail does not automatically
create bridges**. When the bridge links to an external interface, jails are
exposed to the same network as the host.

Note, if you're using both jails and VMs on the same host and want to make them
accessible on the LAN, since *a physical interface can only belong to one
bridge at a time*, it's best to create a bridge that will be shared between
jails and VMs. For example, create `bridge0` and configure vm-bhyve to use it:
`vm switch create -t manual -b bridge0 public`.

<!-- TODO test support for private vnet jails -->
The bridge can also link to a private jail network:

```
# sysrc cloned_interfaces+="bridge0"
# sysrc ifconfig_bridge0="inet 10.0.0.1/24 description jailnet up"
# sysrc gateway_enable="YES"
# sysrc pf_enable="YES"  # adapt accordingly
```

VNET jails are useful when applications insist on binding to 127.0.0.1 (like
Gradle), as each jail gets its own isolated loopback interface.

### Custom

Networking can be fine-tuned and NAT or RDR can be enabled individually,
respectively with the `nat=[0|1|]` and `rdr=[0|1|]` parameters.

These parameters are persisted to `${jail_path}/meta.conf`.

For example, we can enable NAT for outgoing traffic but disable RDR for
incoming traffic:

`sjail create j01 14.2-RELEASE ip4=192.168.1.201/24 nat=1 rdr=0`

One use case for this is a host with a VPN that forwards default traffic to the
VPN server, and jails that:

- are exposed to local network
- can reach out to the internet (ex: pkg install)
- but don't expose ports to the VPN network (`ext_if=tun0`)

A solution to these requirements is a *shared interface* setup and only
enabling NAT for jails.

## Upgrade

Provided the jails don't hold important state, upgrading to a new minor or
major FreeBSD release is best done by re-creating them.

For minor release changes, pointing the jails' `fstab`s to the new release
after stopping them is also a viable option.

## How it works

See [internals](./doc/internals.md).

## Contributing

Feedback and PRs welcome. When hacking on the code, make sure to run tests in
isolated environments (See [t/README.md](./t/README.md) and
[t/integration/README.md](./t/integration/README.md)).

## Credits

- [simple-jails](https://github.com/jpdasma/simple-jails)
- [Bastille](https://github.com/bastilleBSD/bastille)
- [tap.sh](https://github.com/dnmfarrell/tap.sh)

[^1]: themselves inspired by Salt and Docker.

[^2]: One can in theory write `sh` in it and sjail's variables are exposed. But
    so far Bastille commands have fulfilled the needs of many.
