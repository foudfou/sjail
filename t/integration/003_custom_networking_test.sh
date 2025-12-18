#!/bin/sh
# TODO test shared interface and nat=1 expose=0. I.e. host with VPN (or default
# gw is not on LAN) and jail: 1. has access to internet, 2. exposes on LAN,
# 3. does not expose on VPN.
basedir=$(dirname $(realpath "$0"))

. $basedir/pre.sh

tap_end
