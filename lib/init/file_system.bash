source "$BOOTSTRAP_LIB_DIR"/init/file_system/root.bash

if [[ -v BOOTSTRAP_ENABLE_SWAP ]]; then
    source "$BOOTSTRAP_LIB_DIR"/init/file_system/swap.bash
fi
