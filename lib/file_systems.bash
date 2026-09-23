source "$BOOTSTRAP_LIB_DIR"/file_systems/root.bash

if [[ -v BOOTSTRAP_ENABLE_SWAP ]]; then
    source "$BOOTSTRAP_LIB_DIR"/file_systems/swap.bash
fi
