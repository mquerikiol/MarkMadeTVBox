#!/bin/sh

# Read-only home-screen readiness check for Forge or LibreELEC.

project_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd) || exit 1
cd "$project_root" || exit 1

if [ ! -r config/home.conf ]; then
    echo "FAIL: config/home.conf is missing or unreadable"
    exit 1
fi

if [ ! -f docs/HOME_ACTIONS.md ] || [ ! -f docs/SKIN_SELECTION.md ]; then
    echo "FAIL: required home-screen documentation is missing"
    exit 1
fi

if [ ! -r tests/test_home.sh ]; then
    echo "FAIL: tests/test_home.sh is missing or unreadable"
    exit 1
fi

sh -n scripts/check_home_ready.sh || exit 1
sh -n tests/test_home.sh || exit 1

# Reuse the canonical home configuration validation and preserve its failure.
if ! sh tests/test_home.sh >/dev/null 2>&1; then
    echo "FAIL: home configuration validation failed"
    exit 1
fi

# Read the validated configuration without changing it.
# shellcheck disable=SC1091
. config/home.conf || {
    echo "FAIL: config/home.conf could not be loaded"
    exit 1
}

if [ -n "$HOME_BUTTON_1_ACTION" ]; then
    echo "FAIL: Movies/Jellyfin action is configured before Raspberry Pi verification"
    exit 1
fi

echo "PASS: exactly three home buttons and approved Live TV/YouTube actions"
echo "PASS: HOME_ACTIONS.md and SKIN_SELECTION.md are present"
echo "PENDING: Movies/Jellyfin launch action awaits Raspberry Pi verification"
echo "PENDING: home screen is not fully ready until Pi verification is complete"
exit 0
