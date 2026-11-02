# MarkMadeTVBox v1 Home Screen

## Approved layout

The Kodi home screen has exactly three large buttons, presented with large text and clear icons:

1. **Movies** — opens the existing Jellyfin integration.
2. **Live TV** — opens Kodi’s existing PVR/IPTV channels.
3. **YouTube** — opens the Kodi add-on `plugin.video.youtube`.

The design is high contrast, uncluttered, and usable with both a mouse and a remote. Focus states must be obvious, and navigation between the three buttons must be predictable.

The home screen does not include a Settings button, weather, extra widgets, a separate Kodi media library, or a subtitle manager. Administration remains separate from the TV interface and is handled through the project’s normal SSH and LibreELEC administration paths.

## Skin policy

Keep Kodi’s default Estuary skin available as the fallback. Prefer a compatible existing Kodi skin that supports configurable home shortcuts, but do not assume that any particular skin or add-on is installed. Skin and add-on availability must be verified on the Raspberry Pi before configuration or deployment.

No skin XML or Kodi settings are changed by this document.

## Implementation plan

1. Verify the installed Kodi version, available skins, Jellyfin integration, PVR/IPTV channels, and YouTube add-on on the Raspberry Pi.
2. Select a compatible installed skin with configurable home shortcuts; retain Estuary as fallback.
3. Configure only the Movies, Live TV, and YouTube home shortcuts and apply the approved visual treatment.
4. Test mouse and remote navigation, focus visibility, launching, playback, and return-to-home behavior.
5. Record the verified configuration, prepare a reversible backup, and deploy only after testing.

## Acceptance checklist

- [ ] The home screen shows exactly three large buttons: Movies, Live TV, and YouTube.
- [ ] Movies opens the existing Jellyfin integration.
- [ ] Live TV opens Kodi’s existing PVR/IPTV channels.
- [ ] YouTube opens `plugin.video.youtube`.
- [ ] Text and icons are large, high contrast, and readable from the viewing position.
- [ ] All three destinations are usable with a remote and a mouse.
- [ ] No Settings button, weather, extra widgets, separate media library, or subtitle manager is exposed.
- [ ] Estuary remains available as a fallback.
- [ ] The selected skin and add-ons have been verified on the Raspberry Pi.
- [ ] Administration is not exposed in the TV home screen.
