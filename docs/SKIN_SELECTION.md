# MarkMadeTVBox v1 Skin Selection

## Decision

Prefer an existing, lightweight Kodi skin that is already installed or can be verified as compatible with Kodi 21 Omega and that supports configurable home shortcuts. Configure it to expose exactly three large buttons:

1. Movies
2. Live TV
3. YouTube

The buttons must use large labels and icons, high contrast, and predictable remote/mouse focus navigation. No Settings button or additional home-screen buttons, widgets, weather, or decorative clutter are part of v1.

Keep Estuary available and usable as the fallback. Estuary is Kodi’s default skin, but Kodi’s documentation notes that the default skin does not provide the same custom-home-item support as skins designed for configurable main menus. Therefore, Estuary is the safety fallback, not an assumption that it can provide the final three-button layout without modification. See the [Kodi skin documentation](https://kodi.wiki/view/Skins) and [custom home items guidance](https://kodi.wiki/view/Custom_home_items).

## Approach comparison

| Approach | Advantages | Risks and maintenance cost |
|---|---|---|
| Configure an existing skin | Lowest code and maintenance burden; uses Kodi’s supported skin/add-on model; easier to restore to Estuary; avoids maintaining XML across Kodi updates. | The installed skin may not support exactly three shortcuts, may expose unwanted menus/widgets, may have dependencies, or may perform poorly on a Pi 3. Compatibility and behavior must be verified on the actual Pi. |
| Maintain a minimal custom skin | Exact control over the three buttons, layout, contrast, labels, icons, and navigation. | Requires skin XML, packaging, update testing, backup/rollback, and ongoing Kodi 21 compatibility work. A custom skin is additional software to maintain and can fail after Kodi or dependency changes. |

## Recommendation

Use a verified existing lightweight skin with configurable home shortcuts. This is the lowest-maintenance option and best preserves Estuary as a recovery path. Do not select a named alternative in advance or claim compatibility based only on documentation, screenshots, or repository metadata.

If no installed or verifiable skin can produce the exact three-button layout without unwanted menus and widgets, stop the skin-selection step and document that gap. A minimal custom skin may then be evaluated as a separate decision; it is not part of the current implementation.

## Raspberry Pi 3 and Kodi 21 considerations

The selected skin must be evaluated on the Raspberry Pi 3 B+ running Kodi 21 Omega, not only on Forge. Prefer a small visual footprint and avoid unnecessary fanart, animated backgrounds, auto-playing widgets, large media shelves, and extra skin dependencies. The skin must remain responsive when moving focus with the remote and mouse and when returning from Jellyfin, Live TV, or YouTube.

Before selection, inspect the installed skin’s `addon.xml` and dependencies, confirm its declared Kodi GUI compatibility, and verify that it loads under Kodi 21 Omega. Kodi add-ons and skins contain an `addon.xml` describing their version and dependencies; see the [Kodi addon.xml reference](https://kodi.wiki/view/Addon.xml).

## Capabilities requiring verification on the Pi

- The candidate skin is installed and loads successfully on Kodi 21 Omega.
- The candidate supports configurable home shortcuts and can hide all other home entries.
- Exactly Movies, Live TV, and YouTube are visible and selectable.
- Jellyfin’s verified Movies action works from the Movies button.
- `ActivateWindow(TVChannels)` opens the populated PVR/IPTV channel interface.
- `RunAddon(plugin.video.youtube)` works when the YouTube add-on is installed.
- Large labels/icons, contrast, focus states, remote navigation, and mouse navigation are usable at the viewing distance.
- Startup, screen transitions, playback return, and idle behavior are responsive enough for the Pi 3.
- Estuary remains available and can be selected as the fallback after testing.

No skin XML, Kodi settings, or add-ons should be changed until these checks are complete. Administration remains outside the TV home screen.
