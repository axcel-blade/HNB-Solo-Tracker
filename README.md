# HNB Solo Tracker

A Flutter app for logging Solo collection entries. The package name is `hnb_solo_tracker`. The screen title is **Solo Collection Tracker**.

It runs from one codebase on Android, iOS, web, Windows, macOS, and Linux. Entries stay on the device in a Drift SQLite database.

This is an independent tool and is not an official product of Hatton National Bank PLC.

## What it does

- Enter a phone number (trimmed, 7–20 characters) and an entry date.
- Choose **Other Bank** or **HNB**, then a category: **Solo Max**, **Credit/Debit**, **Other Bank acc**, or **HNB ACC**.
- Live counts for those four categories and a **Grand Total**.
- A newest-first list, per-row delete, and an empty state.
- CSV export for a date range (leave both dates blank to export everything).
- JSON backup, JSON import that replaces the current entries after you confirm, and CSV import that keeps existing rows and skips duplicates (same phone, bank, category, and entry date).
- **Clear all entries** after confirmation.

## Requirements

- Flutter stable with Dart `3.12.2` or newer (`environment.sdk` in `pubspec.yaml`)
- For a device build: the usual Android SDK, Xcode (iOS and macOS), or a Linux desktop toolchain

Verified on this Windows machine with Flutter 3.44.3: `flutter analyze`, `flutter test` (12 tests), and `flutter build windows`. macOS, iOS, and Linux were not compiled here.

## Run

```bash
flutter pub get
flutter run -d chrome
flutter run -d windows
flutter run -d android
```

On a Mac:

```bash
flutter run -d ios
flutter run -d macos
```

On Linux:

```bash
flutter run -d linux
```

`flutter devices` lists the targets this machine can launch.

A Windows release build is written to `build/windows/x64/runner/Release/hnb_solo_tracker.exe`:

```bash
flutter build windows
```

## Data

Native mobile and desktop store `solo_collection.sqlite` in the application documents directory (`getApplicationDocumentsDirectory`). On Windows that is `%USERPROFILE%\Documents\solo_collection.sqlite`.

The browser uses the same Drift API with `web/sqlite3.wasm` and `web/drift_worker.js`. The database name is `solo_collection` (IndexedDB, or OPFS when the browser supports it). Nothing is uploaded.

See [docs/DATABASE.md](docs/DATABASE.md).

## Checks

```bash
flutter analyze
flutter test
```

After a schema change, regenerate Drift code:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Documentation

| Document | Description |
|---|---|
| [docs/USER_GUIDE.md](docs/USER_GUIDE.md) | How to enter, export, import, and delete |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Layout and how an entry is saved |
| [docs/DATABASE.md](docs/DATABASE.md) | Drift schema and where the file lives |
| [docs/RELEASING.md](docs/RELEASING.md) | Versioning a release by hand |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Git Flow and pull requests |
| [CHANGELOG.md](CHANGELOG.md) | Version history |
| [SECURITY.md](SECURITY.md) | Reporting vulnerabilities |
| [SUPPORT.md](SUPPORT.md) | Getting help |

## License

[MIT](LICENSE.md) © 2026 AXCEL BLADE
