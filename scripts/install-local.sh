#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage: scripts/install-local.sh install|uninstall

Install or uninstall checkout-owned command links in
${PREFIX:-$HOME/.local}/bin.
EOF
}

if [[ $# -ne 1 ]]; then
    usage >&2
    exit 2
fi

action="$1"
case "$action" in
    install|uninstall) ;;
    -h|--help)
        usage
        exit 0
        ;;
    *)
        usage >&2
        exit 2
        ;;
esac

script_dir=$(CDPATH='' cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH='' cd "$script_dir/.." && pwd -P)

if [[ -n "${PREFIX:-}" ]]; then
    install_prefix="$PREFIX"
elif [[ -n "${HOME:-}" ]]; then
    install_prefix="$HOME/.local"
else
    echo "Error: HOME is unset; set PREFIX to a user-owned directory" >&2
    exit 1
fi

case "$install_prefix" in
    /*) ;;
    *) install_prefix="$PWD/$install_prefix" ;;
esac
bin_dir="$install_prefix/bin"

names=("tk")
targets=("$repo_root/ticket")

while IFS= read -r plugin_name || [[ -n "$plugin_name" ]]; do
    plugin_name="${plugin_name%%#*}"
    plugin_name=$(printf '%s' "$plugin_name" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
    [[ -n "$plugin_name" ]] || continue

    plugin_path="$repo_root/plugins/ticket-$plugin_name"
    if [[ ! -f "$plugin_path" || ! -x "$plugin_path" ]]; then
        echo "Error: curated plugin is missing or not executable: $plugin_path" >&2
        exit 1
    fi

    names+=("ticket-$plugin_name")
    targets+=("$plugin_path")

    for alias_path in "$repo_root"/plugins/ticket-*; do
        [[ -L "$alias_path" ]] || continue
        if [[ "$(readlink "$alias_path")" == "ticket-$plugin_name" ]]; then
            names+=("$(basename "$alias_path")")
            targets+=("$alias_path")
        fi
    done
done < "$repo_root/pkg/extras.txt"

if [[ "$action" == "install" ]]; then
    mkdir -p "$bin_dir"

    conflict=0
    for index in "${!names[@]}"; do
        destination="$bin_dir/${names[$index]}"
        expected="${targets[$index]}"

        if [[ -L "$destination" ]]; then
            if [[ "$(readlink "$destination")" != "$expected" ]]; then
                echo "Refusing to replace existing entry: $destination" >&2
                conflict=1
            fi
        elif [[ -e "$destination" ]]; then
            echo "Refusing to replace existing entry: $destination" >&2
            conflict=1
        fi
    done

    if [[ "$conflict" -ne 0 ]]; then
        echo "Installation aborted; no links were changed" >&2
        exit 1
    fi

    for index in "${!names[@]}"; do
        destination="$bin_dir/${names[$index]}"
        expected="${targets[$index]}"

        if [[ -L "$destination" ]]; then
            echo "Already installed: $destination -> $expected"
        else
            ln -s "$expected" "$destination"
            echo "Installed: $destination -> $expected"
        fi
    done
else
    for index in "${!names[@]}"; do
        destination="$bin_dir/${names[$index]}"
        expected="${targets[$index]}"

        if [[ -L "$destination" && "$(readlink "$destination")" == "$expected" ]]; then
            rm "$destination"
            echo "Removed: $destination"
        elif [[ -e "$destination" || -L "$destination" ]]; then
            echo "Preserved non-checkout entry: $destination"
        fi
    done
fi
