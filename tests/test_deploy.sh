#!/bin/sh

project_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd) || exit 1
sh -n "$project_root/install/deploy.sh" || exit 1

temp_root=${TMPDIR:-/tmp}/markmade-deploy-safety-$$
marker=$temp_root/remote-called
cleanup() {
    rm -rf "$temp_root"
}
trap cleanup EXIT HUP INT TERM

for directory in config lib scripts tests docs install fakebin; do
    mkdir -p "$temp_root/$directory" || exit 1
done
cp "$project_root/install/deploy.sh" "$temp_root/install/deploy.sh" || exit 1
printf '%s\n' placeholder > "$temp_root/config/placeholder"

printf '%s\n' '#!/bin/sh' 'printf called > "$MARKMADE_TEST_MARKER"' 'exit 99' \
    > "$temp_root/fakebin/ssh"
printf '%s\n' '#!/bin/sh' 'printf called > "$MARKMADE_TEST_MARKER"' 'exit 99' \
    > "$temp_root/fakebin/scp"
chmod +x "$temp_root/fakebin/ssh" "$temp_root/fakebin/scp"

printf '%s\n' unsafe > "$temp_root/config/bad name"
if (cd "$temp_root" && PATH="$temp_root/fakebin:$PATH" \
    MARKMADE_TEST_MARKER="$marker" sh install/deploy.sh --deploy test-host \
    >/dev/null 2>&1); then
    echo "FAIL: unsafe filename was accepted"
    exit 1
fi
if [ -e "$marker" ]; then
    echo "FAIL: SSH was reached before unsafe filename rejection"
    exit 1
fi
rm -f "$temp_root/config/bad name"
echo "PASS: unsafe filename rejected before SSH"

ln -s "$temp_root/config/placeholder" "$temp_root/lib/source-link"
if (cd "$temp_root" && PATH="$temp_root/fakebin:$PATH" \
    MARKMADE_TEST_MARKER="$marker" sh install/deploy.sh --deploy test-host \
    >/dev/null 2>&1); then
    echo "FAIL: source symlink was accepted"
    exit 1
fi
if [ -e "$marker" ]; then
    echo "FAIL: SSH was reached before source symlink rejection"
    exit 1
fi
echo "PASS: source symlink rejected before SSH"

exit 0
