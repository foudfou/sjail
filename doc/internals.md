# Internals

## Thin jail

A thin jail is a zfs dataset which comprises: configuration (like `jail.conf`)
and a `root/` directory. This directory is populated by:

- writable directories, like `etc/` or `/var`, copied from the base jail
- a readonly `.ro/` directory onto which the base jail (release) is mounted on jail
  start via jail.conf(5)'s `mount.fstab`
- readonly directories, which are links pointing to `.ro/`, like `bin/` or `usr/sbin/`

*Clone jails* (`zfs clone`) certainly look cool, but as a kind of thick jails,
they eventually diverge from the base and need to be updated individually. They
are recommended for short-lived jails.

## Jail.conf

Each jail has its own `jail.conf`. The general `/etc/jail.conf` has an
`.include` directive so the native `jail(8)` system knows about sjail jails.

The jails' `jail.conf` includes start and stop hooks that enable additional
runtime jail configuration (only related to `pf` at this point):

```
  exec.poststart += "/usr/local/bin/sjail/sjail _hook_start $name";
  exec.prestop   += "/usr/local/bin/sjail/sjail _hook_stop $name";
```
