# Chudmich

A premium liquid-glass Android client for [Immich](https://github.com/immich-app/immich).

Chudmich is a fork of the Immich mobile app at **v3.4.1** and works with **Immich server 3.4.1**. It talks to your server through the unchanged Immich API, so nothing needs to be installed server-side.

## Highlights

- **Liquid glass design system.** Blurred, tinted and lit glass surfaces with a specular rim, derived from the active theme so dynamic color, the primary-color setting and light/dark mode keep working.
- **Redesigned screens.** Photos timeline, library dashboard, albums, search, viewer and settings, plus a floating navigation bar with a sliding glass lens.
- **Spring motion with reduce-motion support.** Interruptible springs for navigation, sheets, press feedback and hero transitions; every animation degrades to instant or a fade when the system disables animations.
- **Faster viewer preloading.** The viewer warms the next images in the direction of travel, so consecutive swipes find their image already decoded.
- **Performance guardrails.** A budget on live blur layers, static glass over scrolling content, cached filters and a background that pauses while you scroll.

Design notes, the list of changes and the performance reasoning are in [`mobile/CHUDMICH.md`](mobile/CHUDMICH.md).

## Install

1. Download the latest `chudmich-*.apk` from the [releases page](https://github.com/jinnbuttcheeks/chudmich/releases). Releases are marked as prereleases.
2. Open the file on your device and allow installation from your browser or file manager when Android asks.

Chudmich uses its own application id, so it installs alongside the official Immich app. Updates install in place over the previous Chudmich build.

- If you installed the first build (`premium-v3.4.1-1`), uninstall it once. It was signed with a temporary key; every later build uses a permanent signing key.
- If you sign in with OAuth and the official Immich app is also installed, Android may show an app chooser when the browser returns to the app. Pick Chudmich.

## Build

Local build (needs the toolchain from `mise.toml` and a few GB of free memory for Gradle; native codegen needs `libclang`):

```sh
mise //mobile:install:ci
mise //mobile:codegen
cd mobile
flutter build apk --release
```

The APK is written to `mobile/build/app/outputs/flutter-apk/app-release.apk`. Without a keystore at `mobile/android/key.jks`, the release build falls back to the debug key, which is fine for local use.

CI is defined in [`.github/workflows/chudmich-android.yml`](.github/workflows/chudmich-android.yml). Pushing a tag that matches `chudmich-v*` (for example `chudmich-v3.4.1-3`) builds a release APK, signs it with the key stored in the `PREMIUM_*` repository secrets and publishes a prerelease named "Chudmich 3.4.1-3". Without the signing secrets the APK is only attached to the workflow run. More detail on signing and packaging is in [`mobile/CHUDMICH.md`](mobile/CHUDMICH.md).

## License and credits

Chudmich is licensed under the [GNU AGPL-3.0](LICENSE), the same license as Immich.

It builds on the work of the [Immich project](https://github.com/immich-app/immich) and its contributors. Please support upstream if you find it useful.

Chudmich is not affiliated with or endorsed by the Immich project. Immich is a trademark of its respective owners.
