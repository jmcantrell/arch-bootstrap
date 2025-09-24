if [[ ! -v BOOTSTRAP_TIMEZONE ]]; then
    if ! timezone=$(timezone); then
        printf "unable to get time zone\n" >&2
        return 1
    fi
    export BOOTSTRAP_TIMEZONE=$timezone
elif ! timedatectl list-timezones | grep -qxF "$BOOTSTRAP_TIMEZONE"; then
    printf "%s: invalid timezone: %s\n" "$0" "$BOOTSTRAP_TIMEZONE" >&2
    return 2
fi
