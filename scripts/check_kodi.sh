#!/bin/sh

# Read-only Kodi/LibreELEC diagnostics. No settings or add-ons are changed.

script_dir=$(CDPATH= cd -- "$(dirname "$0")" 2>/dev/null && pwd)
if [ -n "$script_dir" ]; then
    project_root=$(CDPATH= cd -- "$script_dir/.." 2>/dev/null && pwd)
else
    project_root=.
fi

kodi_addons_dir=${KODI_ADDONS_DIR:-/storage/.kodi/addons}
kodi_userdata_dir=${KODI_USERDATA_DIR:-/storage/.kodi/userdata}

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

echo ""
echo "Skin metadata diagnostics"
echo "========================="

skin_metadata_supported=1
if ! command -v sed >/dev/null 2>&1; then
    skin_metadata_supported=0
    echo "UNKNOWN: sed is unavailable; cannot read skin addon.xml metadata"
fi

skin_metadata_count=0
for skin_root in /usr/share/kodi/addons "$kodi_addons_dir"; do
    if [ ! -d "$skin_root" ]; then
        echo "UNKNOWN: Skin root is unavailable: $skin_root"
        continue
    fi

    for skin_dir in "$skin_root"/skin.*; do
        if [ ! -d "$skin_dir" ]; then
            continue
        fi

        skin_metadata_count=$((skin_metadata_count + 1))
        addon_xml=$skin_dir/addon.xml
        if [ "$skin_metadata_supported" -eq 0 ] || [ ! -r "$addon_xml" ]; then
            echo "UNKNOWN: Skin metadata unavailable for ${skin_dir##*/}"
            echo "UNKNOWN: Configurable home shortcuts for ${skin_dir##*/}"
            continue
        fi

        skin_id=$(sed -n 's:.*<addon[^>]*id="\([^"]*\)"[^>]*>.*:\1:p' "$addon_xml" | sed -n '1p')
        skin_version=$(sed -n 's:.*<addon[^>]*version="\([^"]*\)"[^>]*>.*:\1:p' "$addon_xml" | sed -n '1p')

        if [ -n "$skin_id" ] && [ -n "$skin_version" ]; then
            echo "FOUND: Skin $skin_id version $skin_version (${skin_dir##*/})"
        elif [ -n "$skin_id" ]; then
            echo "UNKNOWN: Skin $skin_id version is missing from addon.xml"
        else
            echo "UNKNOWN: Skin ID/version metadata is unreadable for ${skin_dir##*/}"
        fi

        # Directory presence and addon.xml metadata do not prove configurable
        # home shortcuts. Report UNKNOWN unless explicit evidence is available.
        echo "UNKNOWN: Configurable home shortcuts for ${skin_dir##*/}"
    done
done

if [ "$skin_metadata_count" -eq 0 ]; then
    echo "UNKNOWN: No installed skin directories found for metadata inspection"
fi

estuary_found=0
for skin_root in /usr/share/kodi/addons "$kodi_addons_dir"; do
    if [ -d "$skin_root/skin.estuary" ]; then
        echo "FOUND: Estuary available at $skin_root/skin.estuary"
        estuary_found=1
    fi
done
if [ "$estuary_found" -eq 0 ]; then
    echo "UNKNOWN: Estuary was not found in inspected Kodi add-on roots"
fi

selected_skin_found=0
if [ ! -r "$kodi_userdata_dir/guisettings.xml" ]; then
    echo "UNKNOWN: Kodi selected-skin configuration is unavailable"
elif [ "$skin_metadata_supported" -eq 0 ]; then
    echo "UNKNOWN: sed is unavailable; cannot read selected skin"
else
    selected_skin=$(sed -n \
        's:.*<setting id="lookandfeel.skin"[^>]*>\([^<]*\)</setting>.*:\1:p' \
        "$kodi_userdata_dir/guisettings.xml" | sed -n '1p')
    if [ -n "$selected_skin" ]; then
        echo "FOUND: Selected Kodi skin: $selected_skin"
        selected_skin_found=1
    else
        echo "UNKNOWN: Selected skin setting was not readable"
    fi
fi

if [ "$selected_skin_found" -eq 1 ]; then
    selected_skin_path_found=0
    for skin_root in /usr/share/kodi/addons "$kodi_addons_dir"; do
        if [ -d "$skin_root/$selected_skin" ]; then
            selected_skin_path_found=1
        fi
    done
    if [ "$selected_skin_path_found" -eq 0 ]; then
        echo "UNKNOWN: Selected skin directory was not found in inspected roots"
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
