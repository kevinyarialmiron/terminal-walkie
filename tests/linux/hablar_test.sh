#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
hablar="$repo_root/linux/hablar/hablar"

set +e
output="$($hablar 2>&1)"
status=$?
set -e

if [ "$status" -ne 64 ]; then
    printf 'Expected status 64 without arguments, got %s\n' "$status" >&2
    exit 1
fi

if [ "$output" != 'Uso: hablar "texto a pronunciar"' ]; then
    printf 'Unexpected usage message: %s\n' "$output" >&2
    exit 1
fi
