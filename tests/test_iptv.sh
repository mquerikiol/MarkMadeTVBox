#!/bin/sh

project_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd) || exit 1
cd "$project_root" || exit 1

sh -n lib/iptv.sh || exit 1
sh -n tests/test_iptv.sh || exit 1

. ./lib/iptv.sh

# The configured playlist is provisional and is not created by this test.
output=$(iptv_check "$project_root" 2>&1)
status=$?

case "$output" in
    PASS:*|FAIL:*) ;;
    *)
        echo "FAIL: iptv_check returned an unexpected report"
        exit 1
        ;;
esac

if [ "$status" -eq 0 ]; then
    case "$output" in
        PASS:*) echo "PASS: iptv_check"; exit 0 ;;
        *) echo "FAIL: iptv_check reported PASS with a failure status"; exit 1 ;;
    esac
fi

case "$output" in
    FAIL:*) echo "PASS: iptv_check ($output)"; exit 0 ;;
    *) echo "FAIL: iptv_check reported FAIL with a success status"; exit 1 ;;
esac
