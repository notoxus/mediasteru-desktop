# Electron / Wayland desktop client

This repository contains the Electron desktop client and headless daemon. The Swing app is maintained separately in [mediasteru-java-app](https://github.com/notoxus/mediasteru-java-app).

## Run

```bash
cd mediasteru-desktop
npm install
npm start
```

The app looks for `yt-dlp`, FFmpeg, and Deno in the repository's `tools/` folder
or on `PATH`. These tools are not checksum-verified by this repository.

The project currently uses Electron 41. Electron selects Wayland automatically in a Wayland session; the app does not force X11 or XWayland.

The client currently supports:

- Direct downloads through yt-dlp, FFmpeg, and optional Deno binaries found in `tools/` or on `PATH`.
- Video quality selection from 720p through 2160p or Best, with 1080p as the default.
- MP4 conversion using MKV download, stream copy, then H.264/AAC fallback.
- A built-in temporary Hunting window using Chromium's Network debugger for
  ordinary, Service Worker, iframe, and MSE traffic; no extension or external
  Chromium installation is required.
- An explicit Hunter capture flow: candidates stay scoped to their browser
  window. Response bodies are validated as HLS/DASH manifests instead of
  trusting a URL or MIME type. **Download video** appears only after media
  playback, including playback inside a cross-site iframe. It remains available
  while that video is active and opens a compact format/quality chooser before
  sending the candidate to the review queue.
- Captured Referer/request headers plus target-scoped Hunter session cookies
  are forwarded to the downloader. HLS bodies are snapshotted in Chromium and
  served through a short-lived localhost bridge, so one-shot manifest URLs are
  not requested again. Master HLS manifests are narrowed to the selected quality
  before FFmpeg starts. Sensitive data is redacted from UI/API snapshots.
- A main-process download queue with two concurrent jobs. Each review row starts
  with **Download**, then exposes **Pause/Resume**, **Cancel**, and **Remove** as
  distinct actions. Pause preserves yt-dlp's partial checkpoint; Cancel keeps
  the stopped item in the queue, while Remove deletes the row.
- Bulk JSON import and a local-network companion endpoint on port `8765`.
- A local SQLite media library with search, Play, Open Folder, and Copy Path.
- Optional mpv discovery plus JSON IPC playback control. MP3 files use an
  audio-only queue with Now Playing progress, pause/resume, previous, next,
  stop, and automatic advance; downloading still works when mpv is absent.
- Native folder selection, clipboard paste, status messages, and bounded diagnostic logs.
- A localhost-only v1 control API used by the Rust CLI/TUI. The existing `/add`, `/capture`, and `/ping` companion routes remain compatible with the Android app.

## Terminal client

Keep the desktop app running because it owns the download queue, SQLite library,
dependency discovery, and mpv adapter. Build the CLI from the clients repository:

```bash
cargo build --release --manifest-path ../mediasteru-clients/cli/Cargo.toml
../mediasteru-clients/cli/target/release/mediasteru status
../mediasteru-clients/cli/target/release/mediasteru player
../mediasteru-clients/cli/target/release/mediasteru tui
```

The control API is available only from loopback addresses. For an additional local authentication layer, launch both processes with the same token:

```bash
MEDIASTERU_CONTROL_TOKEN="choose-a-long-random-value" npm start
MEDIASTERU_CONTROL_TOKEN="choose-a-long-random-value" ../mediasteru-clients/cli/target/release/mediasteru status
```

Protocol endpoints are documented in [`TERMINAL_CLIENT.md`](TERMINAL_CLIENT.md); command usage is in the clients repository README.

## Headless Docker mode

`src/daemon.ts` runs the downloader, queue, library, and control API without opening an Electron window. The container installs `yt-dlp` and FFmpeg from the base distribution. The Rust CLI is maintained in the [mediasteru-clients](https://github.com/notoxus/mediasteru-clients) repository and is not bundled in this image.

```bash
docker compose up -d
```

Docker persists downloads through `./downloads` and application state through the `mediasteru-data` volume. On startup, the container assigns those folders to the detected downloads-folder owner and drops root privileges before launching the daemon. Set `MEDIASTERU_UID` and `MEDIASTERU_GID` in the Compose environment if the detected owner is unsuitable. The desktop app and headless container both use port `8765`; run one service at a time.

See [ARCHITECTURE.md](ARCHITECTURE.md) for the core/UI split and extension rules.

Still to migrate before replacing Swing completely:

- Trim filmstrip/range selection.
- Playlist expansion from a pasted page URL.
- App auto-update UI.
- Release packaging and code signing.
- Playback-position tracking and resume.
