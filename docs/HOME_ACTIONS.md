# MarkMadeTVBox v1 Home Actions

The home screen is limited to exactly three buttons: **Movies**, **Live TV**, and **YouTube**. Each button must use a Kodi-supported built-in command; no custom skin code or application wrapper is defined here.

## Action mapping

| Button | Action | Status |
|---|---|---|
| Movies | Use the existing Jellyfin Kodi integration’s verified launch action. The add-on ID and exact action are intentionally not specified until discovered on the Raspberry Pi. | **Requires verification** |
| Live TV | `ActivateWindow(TVChannels)` | **Confirmed built-in action** |
| YouTube | `RunAddon(plugin.video.youtube)` | **Confirmed built-in action; add-on presence still requires Pi verification** |

Kodi documents `ActivateWindow(window)` for opening a GUI window, including `TVChannels`, and documents `RunAddon(id)` for running an add-on. See the [Kodi built-in functions](https://kodi.wiki/view/List_of_built-in_functions) and [Opening Windows and Dialogs](https://kodi.wiki/view/Opening_Windows_and_Dialogs).

### Movies discovery rule

Do not invent a Jellyfin add-on ID, plugin URI, or launch command. When the Raspberry Pi is available, identify the installed Jellyfin-related add-on under Kodi’s add-on directory and confirm its working launch path in Kodi. Record the exact verified action. If the integration is launched as an add-on, the applicable documented form may be `RunAddon(<verified-id>)`; if it is launched as a plugin URI, the applicable documented form may be `RunPlugin(<verified-plugin-uri>)`. Neither placeholder is an approved v1 action until verified.

## Verification on the Raspberry Pi

1. Run the read-only Kodi diagnostics and inspect the installed Jellyfin-related add-ons, `pvr.iptvsimple`, and `plugin.video.youtube`.
2. In Kodi, confirm the existing Jellyfin integration opens Movies and note the installed add-on ID and the action that successfully launches it.
3. Confirm `ActivateWindow(TVChannels)` opens the populated TV channel interface provided by Kodi’s PVR/IPTV setup.
4. Confirm `plugin.video.youtube` is installed and test `RunAddon(plugin.video.youtube)`.
5. Test all three actions from the selected home skin with both remote and mouse navigation.
6. Keep Estuary available and test the verified actions there as the fallback path.

Until these checks are complete, the Live TV and YouTube command forms are documented candidates, while Jellyfin remains unresolved by design.

## Constraints

- Keep the design limited to Movies, Live TV, and YouTube.
- Do not create skin XML or modify Kodi settings as part of defining these actions.
- Do not install add-ons or assume that a skin or integration exists.
- Keep Kodi’s Estuary skin available as the fallback.
