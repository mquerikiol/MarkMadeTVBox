#!/bin/sh

jellyfin_check() {
    if ! command -v curl >/dev/null 2>&1; then
        echo "FAIL: curl is unavailable"
        return 1
    fi

    if [ -z "${JELLYFIN_URL:-}" ]; then
        echo "FAIL: JELLYFIN_URL is not configured"
        return 1
    fi

    status=$(curl -sS --connect-timeout 3 --max-time 8 \
        -o /dev/null -w '%{http_code}' \
        "${JELLYFIN_URL%/}/System/Info/Public") || {
        echo "FAIL: Jellyfin is unreachable"
        return 1
    }

    if [ "$status" = "200" ]; then
        echo "PASS: Jellyfin HTTP 200"
        return 0
    fi

    echo "FAIL: Jellyfin HTTP $status"
    return 1
}
