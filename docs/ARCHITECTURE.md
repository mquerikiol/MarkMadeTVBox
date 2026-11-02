# MarkMadeTVBox Architecture

## Scope

MarkMadeTVBox v1 targets a Raspberry Pi 3 B+ running LibreELEC 12.2.1 and Kodi 21 Omega. The interface is a deliberately simple remote/mouse experience: large text, high contrast, and exactly three large home-screen buttons:

1. **Movies**
2. **Live TV**
3. **YouTube**

There is no Settings button, separate Kodi media library, subtitle manager, or Plex integration. Retro gaming is reserved for v2.

## Runtime architecture

| Component | Responsibility |
|---|---|
| Kodi home screen | Presents the three-button v1 navigation surface. |
| Movies | Connects to the existing Jellyfin server on the Raspberry Pi 4. Continue Watching is optional and, if shown, is provided by Jellyfin. |
| Live TV | Opens and plays the previously verified working IPTV playlist. |
| YouTube | Opens the Kodi YouTube add-on. |
| LibreELEC host | Runs Kodi and provides the target runtime on the Raspberry Pi 3 B+. |
| Administration | Remains outside the home screen; maintenance is performed through SSH and `/storage/isle`. |

The project does not duplicate Jellyfin metadata or create a second Kodi media library. Kodi is the presentation and playback shell; Jellyfin, the IPTV playlist, and the YouTube add-on remain the respective content services.

## Project folders

- `addons/` — Kodi add-on or integration assets.
- `backups/` — deployment and configuration backups.
- `bin/` — executable project utilities.
- `config/` — source configuration and connection definitions.
- `docs/` — architecture and operating documentation.
- `install/` — installation and deployment materials.
- `lib/` — shared implementation modules.
- `logs/` — local development or deployment logs.
- `scripts/` — development, validation, and packaging scripts.
- `tests/` — automated and manual test specifications.
- `themes/` — home-screen visual assets and theme definitions.

Forge is the development environment at `/home/mquerikiol/MarkMadeTVBox`. GitHub stores the source code. LibreELEC deployment is a later, tested release step—not the development environment.

## Implementation order

1. Define the Kodi home-screen layout with only Movies, Live TV, and YouTube, using large high-contrast controls.
2. Configure and test Movies against the existing Jellyfin server on the Raspberry Pi 4; retain Jellyfin-provided Continue Watching only if it works cleanly.
3. Integrate the previously verified IPTV playlist and confirm Live TV playback and remote navigation.
4. Configure YouTube to open the Kodi YouTube add-on.
5. Validate navigation, focus states, readability, playback, and recovery behavior on the development setup.
6. Run the project test checklist and prepare deployment materials and backups.
7. Deploy to LibreELEC only after testing, using SSH and `/storage/isle`; verify the same v1 behavior on the Raspberry Pi 3 B+.

Out of scope for v1: retro gaming, Plex, a separate Kodi media library, subtitle-management UI, and user-facing administration settings.
