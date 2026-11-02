#!/bin/sh

# Read-only Kodi/LibreELEC diagnostics. No settings or add-ons are changed.

script_dir=$(CDPATH= cd -- "$(dirname "$0")" 2>/dev/null && pwd)
if [ -n "$script_dir" ]; then
    project_root=$(CDPATH= cd -- "$script_dir/.." 2>/dev/null && pwd)
else
    project_root=.
fi

kodi_addons_dir=${KODI_ADDONS_DIR:-/storage/.kodi/addons}

echo "Kodi diagnostics"
echo "================"

if command -v kodi >/dev/null 2>&1; then
    kodi_version=$(kodi --version 2>/dev/null)
    if [ -n "$kodi_version" ]; then
        echo "FOUND: Kodi version: $kodi_version"
    else
        echo "UNKNOWN: Kodi version command returned no version"
    fi
else
    echo "UNKNOWN: Kodi command is unavailable"
fi

if [ ! -d "$kodi_addons_dir" ]; then
    echo "UNKNOWN: Kodi add-on directory is unavailable"
else
    skin_count=0
    for skin_dir in "$kodi_addons_dir"/skin.*; do
        if [ -d "$skin_dir" ]; then
            echo "FOUND: Skin directory ${skin_dir##*/}"
            skin_count=$((skin_count + 1))
        fi
    done
    if [ "$skin_count" -eq 0 ]; then
        echo "MISSING: No Kodi skin directories found"
    fi

    if [ -d "$kodi_addons_dir/skin.estuary" ]; then
        echo "FOUND: skin.estuary"
    else
        echo "MISSING: skin.estuary"
    fi

    jellyfin_count=0
    for addon_dir in "$kodi_addons_dir"/*jellyfin* "$kodi_addons_dir"/*Jellyfin*; do
        if [ -d "$addon_dir" ]; then
            echo "FOUND: Jellyfin-related add-on ${addon_dir##*/}"
            jellyfin_count=$((jellyfin_count + 1))
        fi
    done
    if [ "$jellyfin_count" -eq 0 ]; then
        echo "MISSING: Jellyfin-related Kodi add-ons"
    fi

    if [ -d "$kodi_addons_dir/pvr.iptvsimple" ]; then
        echo "FOUND: pvr.iptvsimple"
    else
        echo "MISSING: pvr.iptvsimple"
    fi

    if [ -d "$kodi_addons_dir/plugin.video.youtube" ]; then
        echo "FOUND: plugin.video.youtube"
    else
        echo "MISSING: plugin.video.youtube"
    fi
fi

# Report playlist references and files without reading or printing their contents.
iptv_reference_count=0
iptv_config=$project_root/config/iptv.conf
if [ -f "$iptv_config" ]; then
    if command -v grep >/dev/null 2>&1; then
        if grep -q '^[[:space:]]*IPTV_PLAYLIST=' "$iptv_config" 2>/dev/null; then
            echo "FOUND: IPTV playlist configuration reference"
            iptv_reference_count=$((iptv_reference_count + 1))
        else
            echo "MISSING: IPTV playlist configuration reference"
        fi
    else
        echo "UNKNOWN: Cannot inspect IPTV configuration reference (grep unavailable)"
    fi
else
    echo "UNKNOWN: Project IPTV configuration is unavailable"
fi

for playlist_file in \
    /storage/isle/config/iptv.m3u \
    /storage/isle/config/iptv.m3u8 \
    /storage/.kodi/userdata/addon_data/pvr.iptvsimple/settings.xml; do
    if [ -r "$playlist_file" ]; then
        echo "FOUND: Existing IPTV/PVR reference or playlist file"
        iptv_reference_count=$((iptv_reference_count + 1))
    fi
done

if [ "$iptv_reference_count" -eq 0 ]; then
    echo "MISSING: Existing IPTV playlist references"
fi

exit 0
