if [[ ! -v BOOTSTRAP_ENABLE_ETHERNET ]] && print-network-interfaces | grep -q '^en'; then
    # Flag indicating that wired networking will be used (default: set if there are any network interfaces starting with `en`)
    export BOOTSTRAP_ENABLE_ETHERNET=true
fi
