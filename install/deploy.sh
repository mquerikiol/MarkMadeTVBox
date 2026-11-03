#!/bin/sh

# MarkMadeTVBox deployment helper.
# Default mode is a read-only dry run. This script never changes Kodi or system files.

usage() {
    echo "Usage: $0 [--dry-run|--deploy] RASPBERRY_PI_HOST" >&2
    exit 2
}

mode=dry-run
case "${1:-}" in
    --dry-run)
        mode=dry-run
        shift
        ;;
    --deploy)
        mode=deploy
        shift
        ;;
    --*)
        usage
        ;;
esac

[ "$#" -eq 1 ] || usage
host=$1
case "$host" in
    ""|-*|*" "*)
        echo "FAIL: invalid Raspberry Pi hostname/IP" >&2
        exit 2
        ;;
esac

script_dir=$(CDPATH= cd -- "$(dirname "$0")" 2>/dev/null && pwd) || {
    echo "FAIL: cannot locate project directory" >&2
    exit 1
}
project_root=$(CDPATH= cd -- "$script_dir/.." 2>/dev/null && pwd) || {
    echo "FAIL: cannot locate project root" >&2
    exit 1
}

target_dir=/storage/isle
managed_dirs="config lib scripts tests docs"
temp_dir=${TMPDIR:-/tmp}/markmade-tvbox-deploy-$$

cleanup() {
    rm -f "$temp_dir/files" "$temp_dir/blocked"
    rmdir "$temp_dir" 2>/dev/null || :
}
trap cleanup EXIT HUP INT TERM

if ! command -v find >/dev/null 2>&1; then
    echo "FAIL: find is unavailable" >&2
    exit 1
fi

if ! mkdir "$temp_dir" 2>/dev/null; then
    echo "FAIL: cannot create temporary deployment workspace" >&2
    exit 1
fi

echo "MarkMadeTVBox deployment: $mode"
echo "Source: $project_root"
echo "Target: $host:$target_dir"

for managed_dir in $managed_dirs; do
    if [ ! -d "$project_root/$managed_dir" ]; then
        echo "FAIL: managed directory is missing: $managed_dir" >&2
        exit 1
    fi
done

echo "Validating project shell scripts..."
if ! find "$project_root" \
    -type d \( -name .git -o -name .agents -o -name .codex \) -prune -o \
    -type f -name '*.sh' -exec sh -n {} +; then
    echo "FAIL: shell syntax validation failed" >&2
    exit 1
fi
echo "PASS: shell syntax validation"

# Refuse to copy sensitive or development-only material even if it appears below a
# managed directory. The source tree is not changed by this audit.
for managed_dir in $managed_dirs; do
    find "$project_root/$managed_dir" \
        \( -name .git -o -name .gitmodules -o -name .gitconfig \
        -o -name .codex -o -name .agents \
        -o -name backups -o -iname '*secret*' -o -iname '*credential*' \
        -o -name '.env' -o -iname '*.key' -o -iname '*.pem' \
        -o -iname '*.bak' -o -iname '*.backup' \) -print -quit > "$temp_dir/blocked"
    if [ -s "$temp_dir/blocked" ]; then
        echo "FAIL: sensitive or development-only source material is under $managed_dir" >&2
        exit 1
    fi
done
echo "PASS: source scope audit"

for managed_dir in $managed_dirs; do
    find "$project_root/$managed_dir" -type f -print >> "$temp_dir/files"
done

if [ "$mode" = "dry-run" ]; then
    echo "DRY-RUN: no SSH, backup, or copy operation will be performed"
    echo "DRY-RUN: managed files to copy: $(wc -l < "$temp_dir/files")"
    echo "DRY-RUN: use --deploy $host after reviewing this plan"
    exit 0
fi

if ! command -v ssh >/dev/null 2>&1 || ! command -v scp >/dev/null 2>&1; then
    echo "FAIL: ssh and scp are required for deployment" >&2
    exit 1
fi

echo "Checking SSH connectivity..."
if ! ssh -o BatchMode=yes -o ConnectTimeout=5 "$host" true >/dev/null 2>&1; then
    echo "FAIL: SSH connectivity check failed" >&2
    exit 1
fi
echo "PASS: SSH connectivity"

if ! ssh -o BatchMode=yes -o ConnectTimeout=5 "$host" \
    "test -d '$target_dir'" >/dev/null 2>&1; then
    echo "FAIL: target directory does not exist on the Raspberry Pi: $target_dir" >&2
    exit 1
fi

echo "Checking destination conflicts..."
conflict_count=0
while IFS= read -r source_file; do
    relative_file=${source_file#"$project_root/"}
    case "$relative_file" in
        *"'"*|*" "*)
            echo "FAIL: unsupported unsafe source path: $relative_file" >&2
            exit 1
            ;;
    esac
    ssh -o BatchMode=yes -o ConnectTimeout=5 "$host" \
        "test ! -e '$target_dir/$relative_file'" >/dev/null 2>&1
    remote_status=$?
    if [ "$remote_status" -eq 0 ]; then
        :
    elif [ "$remote_status" -eq 1 ]; then
        echo "CONFLICT: $target_dir/$relative_file"
        conflict_count=$((conflict_count + 1))
    else
        echo "FAIL: could not inspect destination: $target_dir/$relative_file" >&2
        exit 1
    fi
done < "$temp_dir/files"

if [ "$conflict_count" -ne 0 ]; then
    echo "FAIL: $conflict_count destination conflict(s); nothing was copied" >&2
    exit 1
fi
echo "PASS: no destination conflicts"

timestamp=$(date -u '+%Y%m%dT%H%M%SZ') || {
    echo "FAIL: cannot create backup timestamp" >&2
    exit 1
}
backup_path=$target_dir/.markmade-backups/markmade-tvbox-$timestamp.tar.gz
backup_tmp=/tmp/markmade-tvbox-$timestamp.tar.gz

echo "Creating remote backup: $backup_path"
if ! ssh -o BatchMode=yes -o ConnectTimeout=5 "$host" \
    "command -v tar >/dev/null 2>&1 && test ! -e '$backup_path' && mkdir -p '$target_dir/.markmade-backups' && tar -czf '$backup_tmp' --exclude=./.markmade-backups -C '$target_dir' . && mv '$backup_tmp' '$backup_path'"; then
    echo "FAIL: remote backup was not created; nothing was copied" >&2
    exit 1
fi
echo "PASS: remote backup created"

for managed_dir in $managed_dirs; do
    echo "Copying $managed_dir/..."
    if ! scp -r -o BatchMode=yes -o ConnectTimeout=5 \
        "$project_root/$managed_dir" "$host:$target_dir/"; then
        echo "FAIL: copy failed while deploying $managed_dir" >&2
        exit 1
    fi
done

echo "PASS: deployment completed"
exit 0
