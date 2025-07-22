#!/bin/sh
# Commands are used in the context of `sjail apply`: important global
# variables are available and the script runs as root.
#
# We need a running jail to apply recipes, because many operations need it (CMD
# but also PKG, SYSRC or SERVICE), even when run from the host (pkg -j, sysrc
# -j etc.)
set -ue

log_cmd() {
    log "[${jail_name}] ${HLINE} $@ ${HLINE}"
}

CMD() {
    log_cmd "CMD $@"

    # `sh -c` allows for passing env vars (`CMD var1=1 program`) and
    # redirection `CMD "echo OK > /tmp/ok"`, yet making `CMD sh -c` trickier.
    jexec -l "${jail_name}" sh -c "$*"
}

CONF() {
    local param=$1
    log_cmd "CONF $@"

    # split string to array
    OIFS="$IFS"
    IFS='='
    set ${1}
    IFS="$OIFS"

    local k="${1}"
    local v=""
    [ $# -gt 1 ] && v="${2}"

    # jail -m does not persist. sysrc -f not compatible with jail.conf. jail -e
    # does variable expansion so we'd loose readability. We thus resort to wild
    # pattern matching in jail.conf for now.
    #
    # TODO support += notation
    if [ -z "${v}" ]; then
        if grep -m1 -qE "${k}\s*;" "${jail_path}/jail.conf"; then
            :  # already set
        else
            sed -i '' 's|}|  '${k}';\'$'\n''}|' "${jail_path}/jail.conf"
        fi
    elif grep -m1 -qE "${k}\s*=\s*${v}" "${jail_path}/jail.conf"; then
        sed -i '' "s|${k} = .*;|${k} = ${v};|" "${jail_path}/jail.conf"
    else  # append
        sed -i '' 's|}|  '${k}' = '${v}';\'$'\n''}|' "${jail_path}/jail.conf"
    fi

    # jail -mr "name=${jail_name}" "${param}"
    needs_restart=$(($needs_restart+1))
}

CP() {
    local src=$1
    local dst=""
    [ $# -gt 1 ] && dst=$2
    log_cmd "CP $@"

    local recipe_path=$(dirname "${recipe_path}")
    src="${recipe_path}/${src}"
    dst="${zfs_mount}/jails/${jail_name}/root/${dst}"
    # default mode for intermediate directories
    mkdir -p "${dst}"
    cp -a "${src}" "${dst}"
}

EXPOSE() {
    local proto=$1 host_port=$2 jail_port=$3
    log_cmd "EXPOSE $@"

    echo "${proto} ${host_port} ${jail_port}" >> "${jail_path}/rdr.conf"
    needs_restart=$(($needs_restart+1))
}

INCLUDE() {
    local args="$*"
    local recipe=$1; shift
    log_cmd "INCLUDE ${args}"

    while [ $# -gt 0 ]; do
        local arg=$1; shift
        if echo "$arg" | grep -q -E '[^= \t]+=[^= \t]+'; then
            eval "local $arg"
        else
            log_fatal "argument invalid format: ${arg}"
        fi
    done

    # update context
    local recipe_path="${zfs_mount}/recipes/${recipe}/apply.sh"
    . "${recipe_path}"
}

# No checks! Safety not guaranteed.
MOUNT() {
    local args="$*"
    local src=$1; shift
    local dst=$1; shift
    local opts="$@"
    log_cmd "MOUNT ${args}"

    dst="${zfs_mount}/jails/${jail_name}/root/${dst}"
    [ -d "${dst}" ] || mkdir -p "${dst}"

    local line="${src} ${dst} ${opts}"
    local fstab="${zfs_mount}/jails/${jail_name}/fstab"
    if ! grep -qE "${line}" "${fstab}"; then
        echo "$line" >> "${fstab}"
    fi

    # mount immediately otherwise jail -r will complain that dst is not mounted
    mount -F "${fstab}" -a
}

PKG() {
    log_cmd "PKG $@"
    # Not using host: pkg -j "${jail_name}" install -y "$@"
    jexec -l "${jail_name}" pkg install -y "$@"
}

# Convenience function for when CONF is not at the end of the recipe. Ex:
# postgresql recipe. Probably best to hide internals, like sjail variables,
# from user.
RESTART() {
    jail -rc "${jail_name}"
}

SERVICE() {
    log_cmd "SERVICE $@"
    jexec -l "${jail_name}" service "$@"
}

SYSRC() {
    log_cmd "SYSRC $@"
    # Not using host: sysrc -j "${jail_name}" "$@"
    jexec -l -U root "${jail_name}" sysrc "$@"
}
