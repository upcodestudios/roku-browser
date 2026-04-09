# Roku IPTV Prototype

Private Roku IPTV prototype focused on live-channel onboarding, browsing, guide display, and playback.

## What it does
- Supports a built-in sample feed.
- Lets users add custom M3U playlist URLs.
- Lets users add Xtream providers with server URL, username, and password.
- Normalizes channels into a single live-TV catalog with groups, favorites, recents, and guide detail.
- Uses Roku-native video playback for live streams.

## Build
```sh
make -f makefile/root.mk
```

The packaged app is written to `dist/apps/roku-iptv.zip`.

## Sideload
- Build the package with the command above.
- Upload `dist/apps/roku-iptv.zip` directly in the Roku developer installer.
- Do not re-zip the contents manually; the package already contains the required top-level `manifest`, `components/`, and `source/`.
