#!/usr/bin/env bash

# shellcheck disable=SC2034 # HH_EXTRA_* are output variables for the caller.
# Optional compiler and linker flags for Hercules Helper. Keep this file
# compatible with Bash 3.2.

# Return 0 when the given C compiler is Clang (including Apple Clang).
hh_cc_is_clang()
{
    "${1:-cc}" --version 2>/dev/null | head -n 1 | grep -qi clang
}

# Compute extra flags for the Hercules configure step.
#   $1  compiler (e.g. "$CC")
#   $2  true/false: link-time optimization (--lto, upstream issue #58)
#   $3  true/false: disable glibc _FORTIFY_SOURCE (--no-fortify, upstream issue #59)
# Sets HH_EXTRA_CFLAGS and HH_EXTRA_LDFLAGS (possibly empty).
hh_build_extra_flags()
{
    local cc="${1:-cc}" lto="${2:-false}" no_fortify="${3:-false}" lto_flag
    HH_EXTRA_CFLAGS=
    HH_EXTRA_LDFLAGS=

    if [ "$lto" = true ]; then
        if hh_cc_is_clang "$cc"; then
            lto_flag="-flto=thin"
        else
            lto_flag="-flto=auto"
        fi
        HH_EXTRA_CFLAGS="$lto_flag"
        HH_EXTRA_LDFLAGS="$lto_flag"
    fi

    if [ "$no_fortify" = true ]; then
        HH_EXTRA_CFLAGS="${HH_EXTRA_CFLAGS:+$HH_EXTRA_CFLAGS }-U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0"
    fi
}

# Extra CMake defines for the extpkgs builds. CMake picks the right LTO flag
# and the matching archiver (gcc-ar, llvm-ar) itself when IPO is enabled.
#   $1  true/false: link-time optimization
# Sets HH_EXTRA_CMAKE_ARGS (a Bash array).
hh_build_extra_cmake_args()
{
    HH_EXTRA_CMAKE_ARGS=()
    if [ "${1:-false}" = true ]; then
        HH_EXTRA_CMAKE_ARGS=(-DCMAKE_POLICY_DEFAULT_CMP0069=NEW -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON)
    fi
}
