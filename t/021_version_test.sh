#!/bin/sh
. t/pre.sh

t="version"

out=$(sjail version)
tap_ok $? "$t: version success"

echo -e "${out}" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'
tap_ok $? "$t: version semver"

tap_end
