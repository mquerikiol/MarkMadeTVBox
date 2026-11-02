#!/bin/sh

youtube_check() {
    project_root=${1:-${YOUTUBE_PROJECT_ROOT:-.}}
    config_file=$project_root/config/youtube.conf

    if [ ! -r "$config_file" ]; then
        echo "FAIL: YouTube configuration is missing or unreadable"
        return 1
    fi

    # The configuration is project-owned and is loaded relative to the project root.
    # shellcheck disable=SC1090
    . "$config_file" || {
        echo "FAIL: YouTube configuration could not be loaded"
        return 1
    }

    if [ -z "${YOUTUBE_ADDON_ID:-}" ]; then
        echo "FAIL: YouTube add-on ID is not configured"
        return 1
    fi

    kodi_addons_dir=${KODI_ADDONS_DIR:-/storage/.kodi/addons}
    addon_dir=$kodi_addons_dir/$YOUTUBE_ADDON_ID

    if [ -d "$addon_dir" ]; then
        echo "PASS: YouTube add-on directory exists"
        return 0
    fi

    echo "FAIL: YouTube add-on directory is missing"
    return 1
}
