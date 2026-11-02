#!/bin/sh

project_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd) || exit 1
cd "$project_root" || exit 1

sh -n lib/youtube.sh || exit 1
sh -n tests/test_youtube.sh || exit 1

. ./lib/youtube.sh

# Read the existing configuration to classify an absent Forge add-on directory.
# Do not create, install, or modify the Kodi directory.
. ./config/youtube.conf || {
    echo "FAIL: YouTube configuration could not be loaded"
    exit 1
}

kodi_addons_dir=${KODI_ADDONS_DIR:-/storage/.kodi/addons}
addon_dir=$kodi_addons_dir/$YOUTUBE_ADDON_ID

output=$(youtube_check "$project_root" 2>&1)
status=$?

case "$output" in
    PASS:*|FAIL:*) ;;
    *)
        echo "FAIL: youtube_check returned an unexpected report"
        exit 1
        ;;
esac

if [ ! -d "$addon_dir" ]; then
    if [ "$status" -eq 0 ]; then
        echo "FAIL: youtube_check reported success for a missing add-on directory"
        exit 1
    fi
    echo "SKIP: Kodi YouTube add-on directory is absent on Forge"
    exit 0
fi

if [ "$status" -eq 0 ]; then
    case "$output" in
        PASS:*) echo "PASS: youtube_check"; exit 0 ;;
        *) echo "FAIL: youtube_check returned an unexpected success report"; exit 1 ;;
    esac
fi

echo "FAIL: youtube_check failed: $output"
exit 1
