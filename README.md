# sjail

Simple thin jail management tool.

Provides:

1. a straightforward script to create/destroy jails
2. recipes in the form of shell scripts

## Motivation

- Easy to understand.
- Limited rigid feature set:
  - Leverage jail(8) as much as possible;
  - Thin jails only[^1];
  - Networking via cloned loopback interface, with `pf` redirecting rules;

## Usage

Start by creating and reviewing `/usr/local/etc/sjail.conf`:

| `zfs_pool`  | the pool to store all sjail data                              |
| `zfs_mount` | mountpoint for sjail data                                     |
| `loopback`  | the cloned loopback interface for jails                       |
| `pf_ext_if` | the external interface on which traffic for jails is expected |

Following commands are provided:

| Init    | `sjail init`                                                            | Initial setup: zfs, sysrc, networking |
| Fetch   | `sjail fetch 14.1-RELEASE`                                              |                                       |
| Update  | `sjail update 14.1-RELEASE`                                             |                                       |
| Create  | `sjail create alcatraz 14.1-RELEASE ip4=10.1.1.11 ip6=fd10:0:0:100::11` |                                       |
| Destroy | `sjail destroy alcatraz`                                                |                                       |
| List    | `jls` or `sjail list` for all                                           |                                       |
| Start   | `jail -c alcatraz`                                                      |                                       |
| Stop    | `jail -r alcatraz`                                                      |                                       |
| Recipe  | `sjail apply alcatraz some/recipe`                                      |                                       |

## Recipes

Recipes live by convention in `${zfs_mount}/recipes`.

Recipes are directly inspired by Bastille templates. Recipes are `sh` scripts
and commands shell functions.

| `CMD`     |                    |
| `COPY`    | copies recursively |
| `INCLUDE` |                    |
| `MOUNT`   |                    |
| `PKG`     |                    |
| `EXPOSE`  |                    |
| `SERVICE` |                    |
| `SYSRC`   |                    |

## Networking

Sjail only allows for a cloned loopback interface setup. Traffic to from the
host to jails is enabled with `pf`:

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
`proto host_port client_port` lines. They are applied *for ip4 and ip6* via
`pf` rdr rules on jail start and cleared on jail stop.

`rdr.conf` can be created manually of via the recipe `EXPOSE` command.

## Upgrade

Provided the jails doesn't hold important state, upgrading to a new minor or
major release is best done by re-creating them.

For minor release changes, pointing the jails' `fstab`s to the new release
after stopping them is also a viable option.

## Contributing

All feedback and PRs welcome. When hacking on the code, make sure to run tests
in an isolated environment.

## Credits

- [simple-jails](https://github.com/jpdasma/simple-jails)
- [Bastille](https://github.com/bastilleBSD/bastille)

[^1]: *Clone jails* (`zfs clone`) certainly look cool, but as kind of thick
    jails, they eventually diverge from the base and need to be updated
    individually. They are recommended for short-lived jails.
