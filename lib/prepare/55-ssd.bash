if [[ ! -v BOOTSTRAP_USE_TRIM ]] && device-is-ssd "$BOOTSTRAP_INSTALL_DEVICE"; then
    export BOOTSTRAP_USE_TRIM=1
fi
