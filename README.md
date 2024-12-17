# sjail

Simple thin jail management tool.

Provides:

1. a straightforward script to create/destroy jails
2. recipes in the form of Dockerfile-like shell scripts to customize jails

## Motivation

- Easy to understand.
- Limited rigid feature set:
  - Leverage jail(8) as much as possible;
  - ZFS thin jails only;
  - Networking via shared interface or cloned loopback interface and `pf`;

## Usage

```
# make install
```

For loopback networking (optional):

```
# sysrc cloned_interfaces+="lo1"
# service netif cloneup
```

Create and review `/usr/local/etc/sjail.conf`:

|               |                                                                                                                            |
|---------------|----------------------------------------------------------------------------------------------------------------------------|
| `zfs_dataset` | pool to store all sjail data                                                                                               |
| `zfs_mount`   | mountpoint for sjail data                                                                                                  |
| `interface`   | interface to attach jails to. **Dictates the network setup**: `loX` for cloned loopback, anything else is shared interface |
| `pf_ext_if`   | the external interface on which traffic for jails is expected (relevant for loopback networking)                           |


Following commands are provided:

|                 |                                                                         |
|-----------------|-------------------------------------------------------------------------|
| Init            | `sjail init`                                                            |
| Create release  | `sjail rel-create 14.1-RELEASE`                                         |
| Update release  | `sjail rel-update 14.1-RELEASE`                                         |
| Destroy release | `sjail rel-destroy 14.1-RELEASE`                                        |
| Create jail     | `sjail create alcatraz 14.1-RELEASE ip4=10.1.1.11 ip6=fd10:0:0:100::11` |
| Destroy jail    | `sjail destroy alcatraz`                                                |
| List            | `jls` or `sjail list` for all                                           |
| Start           | `jail -c alcatraz`                                                      |
| Stop            | `jail -r alcatraz`                                                      |
| Recipe          | `sjail apply alcatraz some/recipe`                                      |

Compose your own:

|                    |                                                   |
|--------------------|---------------------------------------------------|
| forAll             | `jls name \| xargs …`                             |
| Pkg upgrade forAll | `jls name \| xargs -I% jexec -l % pkg upgrade -y` |
|                    |                                                   |

## Recipes

Recipes live by convention in `${zfs_mount}/recipes`.

Recipes are directly inspired by Bastille templates[^1]. A recipe is a
directory comprised of:

1. A mandatory `apply.sh` file which contains *commands*.
2. Optional files to be deployed via the `CP` command.

`apply.sh` is a shell script[^2]. Commands are shell functions.

|           |                                                                                                 |
|-----------|-------------------------------------------------------------------------------------------------|
| `CMD`     | arguments executed inside `sh -c`. I.e. quote commands with redirects, logical operations, etc. |
| `CONF`    | **breaking compat**: name change + no `set` argument                                            |
| `CP`      | copies recursively                                                                              |
| `INCLUDE` |                                                                                                 |
| `MOUNT`   |                                                                                                 |
| `PKG`     |                                                                                                 |
| `EXPOSE`  | **breaking compat**: name change                                                                |
| `SERVICE` |                                                                                                 |
| `SYSRC`   |                                                                                                 |

### Compatibility with Bastille

When migrating template/recipes from Bastille, here's a little checklist:

- command names; see **breaking compat** in the previous table
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

Optional arguments must still be defined:

```sh
maxmemory=${maxmemory:-}
maxmemory_policy=${maxmemory_policy:-}
```

## Networking

Sjail only supports these networking setups: shared interface or cloned
loopback interface.

### Shared interface

Jails' IPs are attached to the host's external interface and thus accessible to
the local network. No specific `pf` adaptation is required.

### Cloned loopback

Jails' IPs are attached to a clone loopback interface. Traffic between host and
jails is enabled with `pf`: outgoing via NAT, incoming via RDR.

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
`<proto> <host_port> <client_port>` lines. They are applied *for ip4 and ip6*
via `pf` rdr rules on jail start and cleared on jail stop.

`rdr.conf` can be created manually of via the recipe `EXPOSE` command.

## Upgrade

Provided the jails don't hold important state, upgrading to a new minor or
major release is best done by re-creating them.

For minor release changes, pointing the jails' `fstab`s to the new release
after stopping them is also a viable option.

## How it works

See [internals](./doc/internals.md).

## Contributing

All feedback and PRs welcome. When hacking on the code, make sure to run tests
in an isolated environment.

## Credits

- [simple-jails](https://github.com/jpdasma/simple-jails)
- [Bastille](https://github.com/bastilleBSD/bastille)
- [tap.sh](https://github.com/dnmfarrell/tap.sh)

[^1]: themselves inspired by Salt and Docker.

[^2]: One can in theory write `sh` in it and sjail's variables are exposed. But
    so far Bastille commands have fulfilled the needs of many.
