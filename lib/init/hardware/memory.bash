if [[ ! -v BOOTSTRAP_MEMORY_SIZE ]]; then
    if reply=$(print-memory-size); then
        # The amount of memory available (default: parsed from the output of `dmidecode`, i.e. same as ram size, e.g. `16G`)
        export BOOTSTRAP_MEMORY_SIZE=$reply
    fi
    unset reply
fi
