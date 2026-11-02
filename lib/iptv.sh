#!/bin/sh

iptv_check() {
    project_root=${1:-${IPTV_PROJECT_ROOT:-.}}
    config_file=$project_root/config/iptv.conf

    if [ ! -r "$config_file" ]; then
        echo "FAIL: IPTV configuration is missing or unreadable"
        return 1
    fi

    # The configuration is project-owned and is loaded relative to the project root.
    # shellcheck disable=SC1090
    . "$config_file" || {
        echo "FAIL: IPTV configuration could not be loaded"
        return 1
    }

    if [ -z "${IPTV_PLAYLIST:-}" ]; then
        echo "FAIL: IPTV playlist is not configured"
        return 1
    fi

    if [ ! -f "$IPTV_PLAYLIST" ] || [ ! -r "$IPTV_PLAYLIST" ]; then
        echo "FAIL: IPTV playlist is missing or unreadable"
        return 1
    fi

    first_line=
    IFS= read -r first_line < "$IPTV_PLAYLIST"
    case "$first_line" in
        '#EXTM3U'*)
            echo "PASS: IPTV playlist is readable and starts with #EXTM3U"
            return 0
            ;;
        *)
            echo "FAIL: IPTV playlist does not start with #EXTM3U"
            return 1
            ;;
    esac
}
