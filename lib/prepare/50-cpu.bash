if [[ ! -v BOOTSTRAP_CPU_VENDOR ]]; then
    if ! cpu_vendor=$(cpu-vendor); then
        printf "unable to get cpu vendor\n" >&2
        return 1
    fi
    export BOOTSTRAP_CPU_VENDOR=$cpu_vendor
fi

cpu_vendor_package_file=$BOOTSTRAP_CONFIG_DIR/packages/cpu/$BOOTSTRAP_CPU_VENDOR
if [[ ! -f $cpu_vendor_package_file ]]; then
    printf "%s: invalid cpu vendor: %s\n" "$0" "$BOOTSTRAP_CPU_VENDOR" >&2
    return 2
fi
export BOOTSTRAP_CPU_VENDOR_PACKAGE_FILE=$cpu_vendor_package_file
