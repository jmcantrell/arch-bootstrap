# Look for packages *only* in this package repository on a remote system
# If this is set, it's required to also set `BOOTSTRAP_PACKAGE_REPO_NAME`.
# export BOOTSTRAP_PACKAGE_REPO_SERVER=http://packages.local:8080

# Look for packages *only* in this package repository on the live system
# If `BOOTSTRAP_PACKAGE_REPO_NAME` is not set, it will be taken from the first file found in this directory matching `*.db.tar.*`.
# export BOOTSTRAP_PACKAGE_REPO_DIR=/mnt/packages

# The package repository name for `BOOTSTRAP_PACKAGE_REPO_{SERVER,DIR}`
# If `BOOTSTRAP_PACKAGE_REPO_SERVER` is set, this name must be explicitly set.
# If `BOOTSTRAP_PACKAGE_REPO_DIR` is set and this name is not, the name will be taken from the first file found matching `*.db.tar.*`.
# export BOOTSTRAP_PACKAGE_REPO_NAME=custom

if [[ ! -v BOOTSTRAP_PACKAGE_REPO_SERVER && -v BOOTSTRAP_PACKAGE_REPO_DIR ]]; then
    repo_db_file=$(find -L "$BOOTSTRAP_PACKAGE_REPO_DIR" -type f -name "*.db.tar.*" | head -n1)

    if [[ -z $repo_db_file ]]; then
        printf "%s: unable to find any database files in the package repository: %q\n" "$0" "$BOOTSTRAP_PACKAGE_REPO_DIR" >&2
        return 2
    fi

    if [[ ! -v BOOTSTRAP_PACKAGE_REPO_NAME ]]; then
        repo_name=${repo_db_file##*/}
        repo_name=${repo_name%.db.tar.*}
        export BOOTSTRAP_PACKAGE_REPO_NAME=$repo_name
        unset repo_name
    fi

    repo_server=file://$(realpath "$BOOTSTRAP_PACKAGE_REPO_DIR")
    export BOOTSTRAP_PACKAGE_REPO_SERVER=$repo_server
    unset repo_db_file repo_server
fi

if [[ -v BOOTSTRAP_PACKAGE_REPO_SERVER && -z ${BOOTSTRAP_PACKAGE_REPO_NAME:-} ]]; then
    printf "%s: BOOTSTRAP_PACKAGE_REPO_NAME is not set for server: %q\n" "$0" "$BOOTSTRAP_PACKAGE_REPO_SERVER" >&2
    return 2
fi
