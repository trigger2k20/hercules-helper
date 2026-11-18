#!/usr/bin/env bash
# Local unit checks for lib/hercules-helper modules. Runs with Bash 3.2.
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$repo_dir/lib/hercules-helper/common.sh"
source "$repo_dir/lib/hercules-helper/regina.sh"
source "$repo_dir/lib/hercules-helper/platform.sh"
source "$repo_dir/lib/hercules-helper/flags.sh"

fail() { echo "FAIL: $*" >&2; exit 1; }
expect_contains() { case "$1" in *"$2"*) ;; *) fail "expected '$2' in '$1'" ;; esac; }

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# --- Raspberry Pi revision codes (upstream issue #49) -----------------------
expect_contains "$(hh_pi_describe_revision d04190)" "Pi 500"
expect_contains "$(hh_pi_describe_revision E04180)" "CM5"
expect_contains "$(hh_pi_describe_revision c04180)" "4GB"
# Unknown new-style code: decoded, not fatal (Pi 500, 16GB, rev 1.2)
out="$(hh_pi_describe_revision e04192)"
expect_contains "$out" "decoded"
expect_contains "$out" "Pi 500"
expect_contains "$out" "16GB"
# Garbage and empty input never fail
expect_contains "$(hh_pi_describe_revision zzz)" "unknown"
expect_contains "$(hh_pi_describe_revision '')" "unknown"
# Works under set -u with an unset variable, the original failure mode
( unset RPI_REVCODE; hh_pi_describe_revision "${RPI_REVCODE:-}" >/dev/null ) || fail "unset revision code"

# Decoded table entries must agree with the table on memory size
while IFS= read -r line; do
    code="${line%%)*}"; code="${code//[[:space:]]/}"
    hh_pi_known_revision "$code" || fail "table lookup $code"
    table="$HH_PI_NAME"
    if hh_pi_decode_revision "$code"; then
        mem="$(printf '%s' "$HH_PI_NAME" | awk '{for(i=1;i<=NF;i++) if ($i ~ /(MB|GB)$/) print $i}')"
        expect_contains "$table" "$mem"
    fi
done < <(grep -E '^[[:space:]]+[0-9a-f]{6}\) HH_PI_NAME=' "$repo_dir/lib/hercules-helper/platform.sh")

# --- Optional build flags (upstream issues #58, #59) -------------------------
hh_build_extra_flags cc false false
[ -z "$HH_EXTRA_CFLAGS" ] && [ -z "$HH_EXTRA_LDFLAGS" ] || fail "flags must be empty by default"

mkdir -p "$tmp/bin"
printf '#!/bin/sh\necho "gcc (GCC) 14.2.0"\n' > "$tmp/bin/fakegcc"
printf '#!/bin/sh\necho "Apple clang version 17.0.0"\n' > "$tmp/bin/fakeclang"
chmod +x "$tmp/bin/fakegcc" "$tmp/bin/fakeclang"

hh_build_extra_flags "$tmp/bin/fakeclang" true false
[ "$HH_EXTRA_CFLAGS" = "-flto=thin" ] && [ "$HH_EXTRA_LDFLAGS" = "-flto=thin" ] || fail "clang lto: $HH_EXTRA_CFLAGS"
hh_build_extra_flags "$tmp/bin/fakegcc" true true
[ "$HH_EXTRA_CFLAGS" = "-flto=auto -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0" ] || fail "gcc lto+fortify: $HH_EXTRA_CFLAGS"
[ "$HH_EXTRA_LDFLAGS" = "-flto=auto" ] || fail "gcc lto ldflags: $HH_EXTRA_LDFLAGS"
hh_build_extra_flags "$tmp/bin/fakegcc" false true
[ "$HH_EXTRA_CFLAGS" = "-U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0" ] && [ -z "$HH_EXTRA_LDFLAGS" ] || fail "fortify only"

hh_build_extra_cmake_args false
[ ${#HH_EXTRA_CMAKE_ARGS[@]} -eq 0 ] || fail "cmake args must be empty by default"
hh_build_extra_cmake_args true
expect_contains "${HH_EXTRA_CMAKE_ARGS[*]}" "-DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON"

# --- Regina via regina-config, Homebrew Cellar layout (upstream issue #61) ---
cellar="$tmp/Cellar/regina-rexx/3.9.7"
mkdir -p "$cellar/bin" "$cellar/include" "$cellar/lib" "$tmp/brewbin"
touch "$cellar/include/rexxsaa.h"
printf '#!/bin/sh\necho "REXX-Regina_3.9.7(MT) 5.00 18 Mar 2025"\n' > "$cellar/bin/regina"
printf '#!/bin/sh\n[ "$1" = --prefix ] && echo "%s"\n' "$cellar" > "$cellar/bin/regina-config"
chmod +x "$cellar/bin/regina" "$cellar/bin/regina-config"
ln -s "$cellar/bin/regina-config" "$tmp/brewbin/regina-config"
(
    PATH="$tmp/brewbin:$PATH"; CPPFLAGS=; LDFLAGS=
    hh_regina_prepare_environment || fail "regina-config detection"
    [ "$HERCULES_REGINA_PREFIX" = "$cellar" ] || fail "prefix $HERCULES_REGINA_PREFIX"
    expect_contains "$CPPFLAGS" "-I$cellar/include"
    expect_contains "$LDFLAGS" "-L$cellar/lib"
    expect_contains "$(hh_regina_version)" "3.9.7"
)

echo "unit smoke tests passed"
