if [[ ! -v BOOTSTRAP_TIMEZONE ]]; then
    if reply=$(print-timezone); then
        # The system time zone (default: the time zone in the live environment, if set)
        export BOOTSTRAP_TIMEZONE=$reply
    fi
    unset reply
fi

if [[ -v BOOTSTRAP_TIMEZONE ]] && ! zdump "$BOOTSTRAP_TIMEZONE" &>/dev/null; then
    printf "%s: invalid timezone: %s\n" "$0" "$BOOTSTRAP_TIMEZONE" >&2
    return 2
fi
