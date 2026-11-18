#!/usr/bin/env bash

# Platform detection helpers for Hercules Helper. Keep this file compatible
# with Bash 3.2 (no associative arrays), so it can be sourced and tested on
# macOS as well as on the Raspberry Pi itself.

# Known Raspberry Pi revision codes.
# Source: https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#raspberry-pi-revision-codes
# Sets HH_PI_NAME and returns 0 for a known code, returns 1 otherwise.
hh_pi_known_revision()
{
    HH_PI_NAME=
    case "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" in
        900021) HH_PI_NAME="A+        1.1     512MB   Sony UK" ;;
        900032) HH_PI_NAME="B+        1.2     512MB   Sony UK" ;;
        900092) HH_PI_NAME="Zero      1.2     512MB   Sony UK" ;;
        900093) HH_PI_NAME="Zero      1.3     512MB   Sony UK" ;;
        9000c1) HH_PI_NAME="Zero W    1.1     512MB   Sony UK" ;;
        9020e0) HH_PI_NAME="3A+       1.0     512MB   Sony UK" ;;
        902120) HH_PI_NAME="Zero 2 W  1.0     512MB   Sony UK" ;;
        920092) HH_PI_NAME="Zero      1.2     512MB   Embest" ;;
        920093) HH_PI_NAME="Zero      1.3     512MB   Embest" ;;
        900061) HH_PI_NAME="CM        1.1     512MB   Sony UK" ;;
        a01040) HH_PI_NAME="2B        1.0     1GB     Sony UK" ;;
        a01041) HH_PI_NAME="2B        1.1     1GB     Sony UK" ;;
        a02082) HH_PI_NAME="3B        1.2     1GB     Sony UK" ;;
        a020a0) HH_PI_NAME="CM3       1.0     1GB     Sony UK" ;;
        a020d3) HH_PI_NAME="3B+       1.3     1GB     Sony UK" ;;
        a02042) HH_PI_NAME="2B (with BCM2837)         1.2     1GB     Sony UK" ;;
        a21041) HH_PI_NAME="2B        1.1     1GB     Embest" ;;
        a22042) HH_PI_NAME="2B (with BCM2837)         1.2     1GB     Embest" ;;
        a22082) HH_PI_NAME="3B        1.2     1GB     Embest" ;;
        a220a0) HH_PI_NAME="CM3       1.0     1GB     Embest" ;;
        a32082) HH_PI_NAME="3B        1.2     1GB     Sony Japan" ;;
        a52082) HH_PI_NAME="3B        1.2     1GB     Stadium" ;;
        a22083) HH_PI_NAME="3B        1.3     1GB     Embest" ;;
        a02100) HH_PI_NAME="CM3+      1.0     1GB     Sony UK" ;;
        a03111) HH_PI_NAME="4B        1.1     1GB     Sony UK" ;;
        b03111) HH_PI_NAME="4B        1.1     2GB     Sony UK" ;;
        b03112) HH_PI_NAME="4B        1.2     2GB     Sony UK" ;;
        b03114) HH_PI_NAME="4B        1.4     2GB     Sony UK" ;;
        b03115) HH_PI_NAME="4B        1.5     2GB     Sony UK" ;;
        c03111) HH_PI_NAME="4B        1.1     4GB     Sony UK" ;;
        c03112) HH_PI_NAME="4B        1.2     4GB     Sony UK" ;;
        c03114) HH_PI_NAME="4B        1.4     4GB     Sony UK" ;;
        c03115) HH_PI_NAME="4B        1.5     4GB     Sony UK" ;;
        d03114) HH_PI_NAME="4B        1.4     8GB     Sony UK" ;;
        d03115) HH_PI_NAME="4B        1.5     8GB     Sony UK" ;;
        c03130) HH_PI_NAME="Pi 400    1.0     4GB     Sony UK" ;;
        c03131) HH_PI_NAME="Pi 400    1.1     4GB     Sony UK" ;;
        d04190) HH_PI_NAME="Pi 500    1.0     8GB     Sony UK" ;;
        e04190) HH_PI_NAME="Pi 500+   1.1    16GB     Sony UK" ;;
        a03140) HH_PI_NAME="CM4       1.0     1GB     Sony UK" ;;
        b03140) HH_PI_NAME="CM4       1.0     2GB     Sony UK" ;;
        c03140) HH_PI_NAME="CM4       1.0     4GB     Sony UK" ;;
        d03140) HH_PI_NAME="CM4       1.0     8GB     Sony UK" ;;
        c04170) HH_PI_NAME="5B        1.0     4GB            " ;;
        d04170) HH_PI_NAME="5B        1.0     8GB            " ;;
        e04171) HH_PI_NAME="5B        1.1    16GB            " ;;
        c04180) HH_PI_NAME="CM5       1.0     4GB            " ;;
        e04180) HH_PI_NAME="CM5       1.0    16GB            " ;;
        *) return 1 ;;
    esac
    return 0
}

# Decode a new-style revision code (bit 23 set) into type, revision, memory
# and manufacturer, so a Pi model newer than the table above still works.
# Sets HH_PI_NAME and returns 0 on success, returns 1 for old-style or invalid codes.
hh_pi_decode_revision()
{
    local code="$1" value type rev mem maker type_name mem_name maker_name
    HH_PI_NAME=
    case "$code" in ''|*[!0-9a-fA-F]*) return 1 ;; esac
    value=$((16#$code))
    [ $(( (value >> 23) & 1 )) -eq 1 ] || return 1

    rev=$(( value & 0xf ))
    type=$(( (value >> 4) & 0xff ))
    maker=$(( (value >> 16) & 0xf ))
    mem=$(( (value >> 20) & 0x7 ))

    case "$type" in
        0) type_name="A" ;;        1) type_name="B" ;;
        2) type_name="A+" ;;       3) type_name="B+" ;;
        4) type_name="2B" ;;       6) type_name="CM1" ;;
        8) type_name="3B" ;;       9) type_name="Zero" ;;
        10) type_name="CM3" ;;     12) type_name="Zero W" ;;
        13) type_name="3B+" ;;     14) type_name="3A+" ;;
        16) type_name="CM3+" ;;    17) type_name="4B" ;;
        18) type_name="Zero 2 W" ;; 19) type_name="Pi 400" ;;
        20) type_name="CM4" ;;     21) type_name="CM4S" ;;
        23) type_name="5B" ;;      24) type_name="CM5" ;;
        25) type_name="Pi 500" ;;  26) type_name="CM5 Lite" ;;
        *) type_name="type 0x$(printf '%02x' "$type")" ;;
    esac
    case "$mem" in
        0) mem_name="256MB" ;; 1) mem_name="512MB" ;; 2) mem_name="1GB" ;;
        3) mem_name="2GB" ;;   4) mem_name="4GB" ;;   5) mem_name="8GB" ;;
        6) mem_name="16GB" ;;  *) mem_name="?" ;;
    esac
    case "$maker" in
        0) maker_name="Sony UK" ;; 1) maker_name="Egoman" ;;
        2|4) maker_name="Embest" ;; 3) maker_name="Sony Japan" ;;
        5) maker_name="Stadium" ;; *) maker_name="" ;;
    esac

    HH_PI_NAME="$(printf '%-9s 1.%s     %-6s  %s' "$type_name" "$rev" "$mem_name" "$maker_name")"
    return 0
}

# Print a description of a Raspberry Pi revision code. Never fails, so an
# unknown or brand-new board does not abort the build (upstream issue #49).
hh_pi_describe_revision()
{
    local code="$1"
    if hh_pi_known_revision "$code"; then
        printf '%s\n' "$HH_PI_NAME"
    elif hh_pi_decode_revision "$code"; then
        printf '%s (decoded, not in table)\n' "$HH_PI_NAME"
    else
        printf 'unknown model\n'
    fi
}
