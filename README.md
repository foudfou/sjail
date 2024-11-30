# sjails

Simple thin jail management tool.

Provides:

1. a straightforward script to create/destroy jails
2. templates in the form of shell scripts

## Motivation

- Easy to understand; limited feature set.
- Leverage jail(8) as much as possible; provide the bare minimum.
- *Clone jails* (`zfs clone`) can't have their common shared base jail updated.

## Usage

| Fetch        | `sjail fetch 14.1-RELEASE`           |
| Create       | `sjail create alcatraz 14.1-RELEASE` |
| Destroy      | `sjail destroy alcatraz`             |
| List         | `jls` or `sjail list` for all        |
| Start        | `jail -c alcatraz`                   |
| Stop         | `jail -r alcatraz`                   |

## Upgrade

Best to re-create jails after

## Credits

- [simple-jails](https://github.com/jpdasma/simple-jails)
- [Bastille](https://github.com/bastilleBSD/bastille)
