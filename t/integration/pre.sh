#!/bin/sh

#
# Global test variables
#
release="14.1-RELEASE"

# Fresh FreeBSD installs.
vm1=192.168.1.202
vm2=192.168.1.203
jail1=192.168.1.205

#
# Utils
#

trap cleanup 1 2 3 6 15
cleanup() { # re-defined inside tests
    echo "done cleanup ... quitting."
}

suicide() { # intended for non-test commands
    kill -HUP $$
}

. t/tap.sh

#
# Common
#
install_sjail() {
    local vm=$1
    local conf=$2
    local pf=$3

    file_list="sjail/makefile sjail/src"
    tar cf - -C $basedir/../../.. ${file_list} \
        | ssh root@"${vm}" tar xf -

    ssh root@"${vm}" "cd sjail && make install"

    echo "${conf}" | ssh root@"${vm}" -T "cat > /usr/local/etc/sjail.conf"

    echo "$pf" | ssh root@"${vm}" -T "cat > /etc/pf.conf"
    ssh root@"${vm}" "service pf reload" ||true

    ssh root@"${vm}" "sjail init" ||true
}
