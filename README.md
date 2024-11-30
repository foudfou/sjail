# sjails

Simple thin jail management tool.

Provides:

1. a straightforward script to create/destroy jails
2. templates in the form of shell scripts

## Motivation

- Easy to understand.
- Limited rigid feature set:
  - Leverage jail(8) as much as possible;
  - Thin jails only; *Clone jails* (`zfs clone`) can't have their common shared
    base jail updated;
  - Networking via cloned loopback interface, with `pf` redirecting rules;

## Usage

Start by creating and reviewing `/usr/local/etc/sjail.conf`.

| Init     | `sjail init 14.1-RELEASE`                                               | Initial setup: zfs, sysrc, networking |
| Fetch    | `sjail fetch 14.1-RELEASE`                                              |                                       |
| Update   | `sjail update 14.1-RELEASE`                                             |                                       |
| Create   | `sjail create alcatraz 14.1-RELEASE ip4=10.1.1.11 ip6=fd10:0:0:100::11` |                                       |
| Destroy  | `sjail destroy alcatraz`                                                |                                       |
| List     | `jls` or `sjail list` for all                                           |                                       |
| Start    | `jail -c alcatraz`                                                      |                                       |
| Stop     | `jail -r alcatraz`                                                      |                                       |
| Template | `sjail apply alcatraz some/templ`                                       |                                       |

## Templates

Templates live by convention in `${zfs_mount}/templates`.

Templates are directly inspired by Bastille. Templates are `sh` scripts and
commands shell functions.

| `CMD`     |                    |
| `COPY`    | copies recursively |
| `INCLUDE` |                    |
| `MOUNT`   |                    |
| `PKG`     |                    |
| `EXPOSE`  |                    |
| `SERVICE` |                    |
| `SYSRC`   |                    |

## Networking

Sjails only allows for a cloned loopback interface setup. Traffic to from the
host to jails is enabled with `pf`:

```
TODO pf conf
```

Port forwarding is persisted to `${jail_path}/rdr.conf` as
`PROTO HOST_PORT CLIENT_PORT` lines. They are applied *for ip4 and ip6* via
`pf` rdr rules on jail start and cleared on jail stop.

## Upgrade

Provided the jails doesn't hold important state, upgrading to a new minor or
major release is best done by re-creating them.

For minor release changes, pointing the jails' `fstab`s to the new release
after stopping them is also a viable option.

## Credits

- [simple-jails](https://github.com/jpdasma/simple-jails)
- [Bastille](https://github.com/bastilleBSD/bastille)
