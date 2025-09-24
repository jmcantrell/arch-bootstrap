bootstrap_source() {
    local file
    for file in "${@:?missing file(s)}"; do
        if ! . "$file"; then
            printf "unable to source file: %q\n" "$file" >&2
            return 1
        fi
    done
}

bootstrap_try_source() {
    local file
    for file in "${@:?missing file(s)}"; do
        if [[ -f $file ]]; then
            bootstrap_source "$file" || return
        fi
    done
}
