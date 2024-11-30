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

| Create  | `sjail create alcatraz 14.1-RELEASE` |
| Destroy | `sjail destroy alcatraz`             |
| List    | `jls`                                |
| Start   | `jail -c alcatraz`                   |
| Stop    | `jail -r alcatraz`                   |

## Credits

- [simple-jails](https://github.com/jpdasma/simple-jails)
- [Bastille](https://github.com/bastilleBSD/bastille)
