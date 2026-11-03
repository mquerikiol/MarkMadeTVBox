#!/bin/sh

usage() {
    echo "Usage: $0 [--dry-run|--deploy] RASPBERRY_PI_HOST" >&2
    exit 2
}

mode=dry-run
case "${1:-}" in
    --dry-run) shift ;;
    --deploy) mode=deploy; shift ;;
    --*) usage ;;
esac
[ "$#" -eq 1 ] || usage
host=$1
case "$host" in
    ""|-*|*[!A-Za-z0-9.@:_-]*)
        echo "FAIL: invalid Raspberry Pi hostname/IP" >&2
        exit 2
        ;;
esac

script_dir=$(CDPATH= cd -- "$(dirname "$0")" 2>/dev/null && pwd) || exit 1
project_root=$(CDPATH= cd -- "$script_dir/.." 2>/dev/null && pwd) || exit 1
target_dir=/storage/isle
managed_dirs="config lib scripts tests docs"
temp_dir=${TMPDIR:-/tmp}/markmade-tvbox-deploy-$$

cleanup() {
    rm -f "$temp_dir/files" "$temp_dir/blocked"
    rmdir "$temp_dir" 2>/dev/null || :
}
trap cleanup EXIT HUP INT TERM

command -v find >/dev/null 2>&1 || {
    echo "FAIL: find is unavailable" >&2
    exit 1
}
mkdir "$temp_dir" 2>/dev/null || {
    echo "FAIL: cannot create temporary deployment workspace" >&2
    exit 1
}

echo "MarkMadeTVBox deployment: $mode"
echo "Target: $host:$target_dir"

for managed_dir in $managed_dirs; do
    [ -d "$project_root/$managed_dir" ] || {
        echo "FAIL: managed directory is missing: $managed_dir" >&2
        exit 1
    }
done

if ! find "$project_root" \
    -type d \( -name .git -o -name .agents -o -name .codex \) -prune -o \
    -type f -name '*.sh' -exec sh -n {} +; then
    echo "FAIL: shell syntax validation failed" >&2
    exit 1
fi
echo "PASS: shell syntax validation"

for managed_dir in $managed_dirs; do
    find "$project_root/$managed_dir" \
        \( -name .git -o -name .gitmodules -o -name .gitconfig -o -name .codex \
        -o -name .agents -o -name backups -o -iname '*secret*' \
        -o -iname '*credential*' -o -name '.env' -o -iname '*.key' \
        -o -iname '*.pem' -o -iname '*.bak' -o -iname '*.backup' \) \
        -print -quit > "$temp_dir/blocked"
    [ ! -s "$temp_dir/blocked" ] || {
        echo "FAIL: sensitive or development-only source material found" >&2
        exit 1
    }
    source_links=$(find "$project_root/$managed_dir" -type l -print -quit)
    [ -z "$source_links" ] || {
        echo "FAIL: source symbolic link found under $managed_dir" >&2
        exit 1
    }
    source_special=$(find "$project_root/$managed_dir" \
        \( -type b -o -type c -o -type p -o -type s \) -print -quit)
    [ -z "$source_special" ] || {
        echo "FAIL: unexpected source file type found under $managed_dir" >&2
        exit 1
    }
done
echo "PASS: source scope and file-type audit"

: > "$temp_dir/files" || exit 1
for managed_dir in $managed_dirs; do
    find "$project_root/$managed_dir" -type f -print >> "$temp_dir/files" || exit 1
done
file_count=$(wc -l < "$temp_dir/files")
[ "$file_count" -gt 0 ] || {
    echo "FAIL: no audited regular files are available" >&2
    exit 1
}

validate_relative_path() {
    path=$1
    case "$path" in
        ""|/*|*[!A-Za-z0-9._/-]*|*//*|.|..|./*|*/./*|*/.|../*|*/../*|*/..)
            return 1
            ;;
        config/*|lib/*|scripts/*|tests/*|docs/*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Validate the complete manifest before any SSH, SCP, backup, or remote action.
while IFS= read -r source_file; do
    rel=${source_file#"$project_root/"}
    if ! validate_relative_path "$rel"; then
        echo "FAIL: unsafe or unmanaged source path: $rel" >&2
        exit 1
    fi
done < "$temp_dir/files"
echo "PASS: source paths are safe and managed"

if [ "$mode" = "dry-run" ]; then
    echo "DRY-RUN: no SSH, backup, or copy operation will be performed"
    echo "DRY-RUN: audited regular files: $file_count"
    exit 0
fi

command -v ssh >/dev/null 2>&1 && command -v scp >/dev/null 2>&1 || {
    echo "FAIL: ssh and scp are required" >&2
    exit 1
}
ssh -o BatchMode=yes -o ConnectTimeout=5 "$host" true >/dev/null 2>&1 || {
    echo "FAIL: SSH connectivity check failed" >&2
    exit 1
}
echo "PASS: SSH connectivity"

ssh -o BatchMode=yes -o ConnectTimeout=5 "$host" sh -s -- "$target_dir" <<'REMOTE_ROOT'
target=$1
[ -d "$target" ] && [ ! -L "$target" ] || exit 13
REMOTE_ROOT
[ "$?" -eq 0 ] || {
    echo "FAIL: destination root is missing, not a directory, or a symlink" >&2
    exit 1
}

check_destination() {
    rel=$1
    ssh -o BatchMode=yes -o ConnectTimeout=5 "$host" sh -s -- \
        "$target_dir" "$rel" <<'REMOTE_CHECK'
target=$1
rel=$2
dest=$target/$rel
[ -d "$target" ] && [ ! -L "$target" ] || exit 13
parent=$dest
case "$parent" in */*) parent=${parent%/*} ;; esac
while [ "$parent" != "$target" ]; do
    [ ! -L "$parent" ] || exit 11
    if [ -e "$parent" ] && [ ! -d "$parent" ]; then exit 12; fi
    parent=${parent%/*}
done
[ ! -L "$dest" ] || exit 10
if [ -e "$dest" ]; then
    [ -f "$dest" ] && exit 20
    exit 21
fi
exit 0
REMOTE_CHECK
}

conflicts=0
while IFS= read -r source_file; do
    rel=${source_file#"$project_root/"}
    check_destination "$rel"
    status=$?
    case "$status" in
        0) ;;
        10) echo "CONFLICT: destination symlink: $rel"; conflicts=$((conflicts + 1)) ;;
        11) echo "CONFLICT: parent symlink: $rel"; conflicts=$((conflicts + 1)) ;;
        12) echo "CONFLICT: parent unexpected type: $rel"; conflicts=$((conflicts + 1)) ;;
        20) echo "CONFLICT: destination file exists: $rel"; conflicts=$((conflicts + 1)) ;;
        21) echo "CONFLICT: destination unexpected type: $rel"; conflicts=$((conflicts + 1)) ;;
        *) echo "FAIL: destination inspection failed: $rel" >&2; exit 1 ;;
    esac
done < "$temp_dir/files"
[ "$conflicts" -eq 0 ] || {
    echo "FAIL: destination conflicts found; nothing was copied" >&2
    exit 1
}

stamp=$(date -u '+%Y%m%dT%H%M%SZ') || exit 1
backup=$target_dir/.markmade-backups/markmade-tvbox-$stamp.tar.gz
backup_tmp=/tmp/markmade-tvbox-$stamp.tar.gz
ssh -o BatchMode=yes -o ConnectTimeout=5 "$host" sh -s -- \
    "$target_dir" "$backup" "$backup_tmp" <<'REMOTE_BACKUP'
target=$1
backup=$2
tmp=$3
[ -d "$target" ] && [ ! -L "$target" ] || exit 30
command -v tar >/dev/null 2>&1 || exit 31
[ ! -e "$backup" ] && [ ! -L "$backup" ] || exit 32
[ ! -e "$tmp" ] && [ ! -L "$tmp" ] || exit 32
dir=${backup%/*}
[ ! -L "$dir" ] || exit 33
if [ -e "$dir" ] && [ ! -d "$dir" ]; then exit 33; fi
mkdir -p "$dir" || exit 34
tar -czf "$tmp" -C "$target" . || exit 35
[ -s "$tmp" ] || exit 36
mv "$tmp" "$backup" || exit 37
[ -s "$backup" ] && tar -tzf "$backup" >/dev/null 2>&1 || exit 38
REMOTE_BACKUP
[ "$?" -eq 0 ] || {
    echo "FAIL: remote backup was not created and verified" >&2
    exit 1
}
echo "PASS: remote backup created and verified"

install_file() {
    rel=$1
    source_file=$project_root/$rel
    remote_tmp=/tmp/markmade-tvbox-$stamp-$$-${rel##*/}
    ssh -o BatchMode=yes -o ConnectTimeout=5 "$host" sh -s -- "$remote_tmp" <<'REMOTE_TMP'
tmp=$1
[ ! -e "$tmp" ] && [ ! -L "$tmp" ] || exit 40
REMOTE_TMP
    [ "$?" -eq 0 ] || return 1
    scp -o BatchMode=yes -o ConnectTimeout=5 "$source_file" "$host:$remote_tmp" >/dev/null || return 1
    ssh -o BatchMode=yes -o ConnectTimeout=5 "$host" sh -s -- \
        "$target_dir" "$remote_tmp" "$rel" <<'REMOTE_INSTALL'
target=$1
tmp=$2
rel=$3
dest=$target/$rel
[ -f "$tmp" ] && [ ! -L "$tmp" ] || exit 41
[ -d "$target" ] && [ ! -L "$target" ] || exit 42
parent=$dest
case "$parent" in */*) parent=${parent%/*} ;; esac
while [ "$parent" != "$target" ]; do
    [ ! -L "$parent" ] || exit 44
    if [ -e "$parent" ] && [ ! -d "$parent" ]; then exit 45; fi
    parent=${parent%/*}
done
mkdir -p "${dest%/*}" || exit 43
parent=${dest%/*}
while [ "$parent" != "$target" ]; do
    [ ! -L "$parent" ] || exit 44
    if [ -e "$parent" ] && [ ! -d "$parent" ]; then exit 45; fi
    parent=${parent%/*}
done
[ ! -L "$dest" ] && [ ! -e "$dest" ] || exit 46
set -C
cat "$tmp" > "$dest" || exit 47
set +C
rm -f "$tmp" || exit 48
REMOTE_INSTALL
    [ "$?" -eq 0 ] || return 1
    echo "PASS: copied $rel"
}
while IFS= read -r rel; do
    install_file "$rel" || {
        echo "FAIL: deployment stopped; previously copied files were preserved" >&2
        exit 1
    }
done < "$temp_dir/files"

echo "PASS: deployment completed without overwriting existing files"
exit 0
