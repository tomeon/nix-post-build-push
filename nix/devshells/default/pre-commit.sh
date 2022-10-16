#!/usr/bin/env bash

if git rev-parse --verify HEAD &>/dev/null; then
    against=HEAD
else
    # Initial commit: diff against an empty tree object
    against="$(git hash-object -t tree /dev/null)" || exit
fi

BAIL_OUT() {
    rc="$?"
    printf -- '%b\n' "$@"
    exit "$rc"
}

git_diff_against() {
    git diff-index --name-only --cached "${against?}" --diff-filter d "$@"
}

if command -v mkdoc &>/dev/null; then
    # shellcheck disable=SC2016
    mkdoc --verify || BAIL_OUT '\nChecking for documentation updates with mkdoc failed' \
        '\nPlease generate documentation with `mkdoc`'
fi

git_diff_against -z -- '*.nix' | xargs -r -0 alejandra --quiet --check || BAIL_OUT '\nLinting with alejandra failed'

git_diff_against -z | xargs -r -0 editorconfig-checker -- || BAIL_OUT '\nLinting with editorconfig-checker failed'
