#!/bin/sh

project_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd) || exit 1
cd "$project_root" || exit 1

config_file=config/home.conf
sh -n tests/test_home.sh || exit 1

if [ ! -r "$config_file" ]; then
    echo "FAIL: home configuration is missing or unreadable"
    exit 1
fi

seen_count=0
seen_1_label=0
seen_1_action=0
seen_2_label=0
seen_2_action=0
seen_3_label=0
seen_3_action=0

while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
        ""|\#*)
            ;;
        HOME_BUTTON_COUNT=*)
            seen_count=$((seen_count + 1))
            ;;
        HOME_BUTTON_1_LABEL=*)
            seen_1_label=$((seen_1_label + 1))
            ;;
        HOME_BUTTON_1_ACTION=*)
            seen_1_action=$((seen_1_action + 1))
            ;;
        HOME_BUTTON_2_LABEL=*)
            seen_2_label=$((seen_2_label + 1))
            ;;
        HOME_BUTTON_2_ACTION=*)
            seen_2_action=$((seen_2_action + 1))
            ;;
        HOME_BUTTON_3_LABEL=*)
            seen_3_label=$((seen_3_label + 1))
            ;;
        HOME_BUTTON_3_ACTION=*)
            seen_3_action=$((seen_3_action + 1))
            ;;
        *)
            echo "FAIL: unexpected home configuration entry"
            exit 1
            ;;
    esac
done < "$config_file"

if [ "$seen_count" -ne 1 ] || [ "$seen_1_label" -ne 1 ] || \
    [ "$seen_1_action" -ne 1 ] || [ "$seen_2_label" -ne 1 ] || \
    [ "$seen_2_action" -ne 1 ] || [ "$seen_3_label" -ne 1 ] || \
    [ "$seen_3_action" -ne 1 ]; then
    echo "FAIL: configuration does not define exactly three complete buttons"
    exit 1
fi

# shellcheck disable=SC1090
. "$config_file" || {
    echo "FAIL: home configuration could not be loaded"
    exit 1
}

if [ "$HOME_BUTTON_COUNT" != "3" ]; then
    echo "FAIL: HOME_BUTTON_COUNT must be 3"
    exit 1
fi

if [ "$HOME_BUTTON_1_LABEL" != "Movies" ] || \
    [ "$HOME_BUTTON_2_LABEL" != "Live TV" ] || \
    [ "$HOME_BUTTON_3_LABEL" != "YouTube" ]; then
    echo "FAIL: home buttons are not in the approved order"
    exit 1
fi
echo "PASS: exactly three home buttons in the approved order"

if [ "$HOME_BUTTON_2_ACTION" != "ActivateWindow(TVChannels)" ]; then
    echo "FAIL: unexpected Live TV action"
    exit 1
fi
echo "PASS: Live TV action"

if [ "$HOME_BUTTON_3_ACTION" != "RunAddon(plugin.video.youtube)" ]; then
    echo "FAIL: unexpected YouTube action"
    exit 1
fi
echo "PASS: YouTube action"

if [ -n "$HOME_BUTTON_1_ACTION" ]; then
    echo "FAIL: Movies action must remain unconfigured until Jellyfin is verified"
    exit 1
fi
echo "PENDING: Movies action awaits Raspberry Pi Jellyfin verification"

exit 0
