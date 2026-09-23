if [[ ! -v BOOTSTRAP_CPU_VENDOR ]]; then
    if ! reply=$(print-cpu-vendor); then
        printf "unable to get cpu vendor\n" >&2
        return 1
    fi
    # The vendor of the system's CPU (choices: `intel` or `amd`, default: parsed from `vendor_id` in `/proc/cpuinfo`)
    export BOOTSTRAP_CPU_VENDOR=$reply
    unset reply
fi

package_file=$BOOTSTRAP_CONFIG_DIR/packages/hardware/cpu_vendors/$BOOTSTRAP_CPU_VENDOR

if [[ ! -f $package_file ]]; then
    printf "%s: invalid cpu vendor: %s\n" "$0" "$BOOTSTRAP_CPU_VENDOR" >&2
    return 2
fi

export BOOTSTRAP_CPU_VENDOR_PACKAGE_FILE=$package_file
unset package_file
