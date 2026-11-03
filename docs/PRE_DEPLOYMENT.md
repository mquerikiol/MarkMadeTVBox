# MarkMadeTVBox Pre-Deployment Checklist

Target: Raspberry Pi 3 B+, LibreELEC 12.2.1, Kodi 21 Omega.

Deployment is not approved until every pending Raspberry Pi check is complete. No checklist item below implies that the TV home screen or any integration is already working.

## Completed on Forge

- [x] Project files are maintained in `/home/mquerikiol/MarkMadeTVBox`.
- [x] Shell scripts pass `sh -n` validation through the deployment preflight.
- [x] IPTV, YouTube, home configuration, and deployment safety tests run without installing or modifying Kodi components.
- [x] Deployment defaults to dry-run, audits source files, rejects symlinks and unsafe paths, checks conflicts, and avoids recursive `scp`.
- [x] Deployment is limited to `config/`, `lib/`, `scripts/`, `tests/`, and `docs/`.
- [x] The deployment script has a local backup before the current edit: `/tmp/markmade-deploy.sh.20261103T010535Z.bak`.

## Pending Raspberry Pi checks

### Source and access

- [ ] Confirm the Forge working tree contains the intended changes and has no unexpected files.
- [ ] Synchronize the intended source with GitHub and verify the expected revision. Do not deploy unreviewed or unpushed changes.
- [ ] Confirm SSH access to the Pi using its current hostname/IP; do not reuse an old address.
- [ ] Confirm `/storage/isle` exists, is a real directory, and is writable by the deployment account.

### Backup and conflict safety

- [ ] Run deployment preflight and review every destination conflict, parent-directory conflict, and symlink warning.
- [ ] Create and verify the timestamped backup of existing `/storage/isle` files before copying anything.
- [ ] Stop if any managed destination file already exists; do not overwrite it automatically.
- [ ] Record the backup location and retain it for rollback.

### Services and integrations

- [ ] From the Pi, verify Jellyfin server connectivity using the actual Raspberry Pi 4 address. Forge’s `127.0.0.1:8096` refers to Forge itself and is not reachable as the Jellyfin server from the Pi.
- [ ] Confirm the existing Jellyfin Kodi integration and record its installed add-on ID and working Movies launch action; do not invent either value.
- [ ] Confirm the previously verified IPTV playlist’s actual location on the Pi. `/storage/isle/config/iptv.m3u` is currently only a provisional configuration path and must not be assumed to exist.
- [ ] Confirm `pvr.iptvsimple` is installed, enabled, and can open the existing PVR/IPTV channels without rescanning or replacing the playlist.
- [ ] Confirm `plugin.video.youtube` is installed and verify that `RunAddon(plugin.video.youtube)` launches it.

### Kodi skin and home screen

- [ ] Inspect installed skin IDs, versions, dependencies, and Kodi 21 compatibility on the Pi.
- [ ] Keep Estuary available and confirm it can be restored as the fallback.
- [ ] Verify the selected skin can expose exactly three large home buttons: Movies, Live TV, and YouTube.
- [ ] Confirm there is no Settings button, weather, extra widget, separate media library, or subtitle manager on the TV home screen.
- [ ] Confirm the Jellyfin, `ActivateWindow(TVChannels)`, and YouTube actions work from the selected skin.

### User and recovery testing

- [ ] Test large text, icons, contrast, focus states, and navigation with both the remote and a mouse.
- [ ] Test Movies, Live TV, and YouTube playback, return-to-home behavior, and failure handling.
- [ ] Reboot the Pi and confirm Kodi starts with the intended home screen and integrations still available.
- [ ] Verify administration remains separate through SSH and `/storage/isle`.
- [ ] Perform a final backup after successful testing and record the rollback procedure.

## Deployment decision

Deploy only when the pending Pi checks pass, the backup is verified, no conflicts remain, and rollback has been tested or documented. If any integration, skin, playlist, or action is unverified, stop and leave the existing LibreELEC/Kodi installation unchanged.
