# HNB Solo Tracker

A Flutter app for customer registration and lead analytics. The package name is `hnb_solo_tracker`. The screen title is **HNB Solo Tracker**. The subtitle is **Customer Registration & Lead Analytics Portal**. The header badge shows the app version from this release (`v1.2.0`).

It runs from one codebase on Android, iOS, web, Windows, macOS, and Linux. Registrations stay on the device in a Drift SQLite database.

This is an independent tool and is not an official product of Hatton National Bank PLC.

![HNB Solo Tracker icon](assets/icons/app_icon.png)

The launcher icon is a collection list, in the app blue (`#2463EB`) with navy checks (`#10233F`). Source art is in `assets/icons/`. See [Architecture](docs/ARCHITECTURE.md#launcher-icon) to regenerate platform sizes. The portal screen itself uses a dark navy and gold layout.

## What it does

- Enter a contact or reference number (a phone number or a short reference such as `Ref #1029`). Empty text is rejected. There is no 7-character minimum. The stored value is trimmed and at most 120 characters.
- Choose **HNB Bank** or **Other Bank**.
- For HNB: member status **Old Active Member** or **New Active Member**, and product **SOLO MAX** or **HNB ACC**.
- For Other Bank: payment source **Credit/Debit Card** or **Bank Account**. The product is stored as **External App**.
- Choose an acquisition channel:
  - **HNB Branch** — 256 Sri Lankan branches. Negombo branches are first, then the other named branches, then generated names such as `HNB Branch Ref #101`.
  - **Department** — an HNB Tower department. The detail is stored as `HNB Tower - {department}`.
  - **Own Visit** — free text. Blank text is stored as `Direct Own Visit`.
- KPI cards: **Total Registrations**, **HNB Members** (with the percent of all entries), **Other Banks**, **Branches**, **HNB Tower Depts**, and **Own Visits**.
- Charts for the bank provider ratio and the channel breakdown.
- A searchable registrations log, newest first, with per-row delete.
- **Export Data** for a required start and end date. The range is inclusive. Download CSV or JSON. Import CSV and Import JSON are in that same dialog. Older collection CSV and JSON backups still import and are mapped into the current record shape.
- **Clear All Data** after confirmation.
- **Settings** for the place lists, a GitHub release check, and the developer credit. The registration form does not open the old place and category dialog. The check does not install an update. It opens the GitHub release page.
- Settings credits [Axcel Blade](https://github.com/axcel-blade) (`@axcel-blade`).

## Requirements

- Flutter stable with Dart `3.12.2` or newer (`environment.sdk` in `pubspec.yaml`)
- For a device build: the usual Android SDK, Xcode (iOS and macOS), or a Linux desktop toolchain

Verified on this Windows machine with Flutter 3.44.3: `flutter analyze`, `flutter test` (22 tests), and `flutter build windows`. macOS, iOS, and Linux were not compiled here.

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

Native mobile and desktop store `solo_collection.sqlite` in the application documents directory (`getApplicationDocumentsDirectory`). On Windows that is `%USERPROFILE%\Documents\solo_collection.sqlite`. Schema version 3 stores the registration fields in that same file. Older rows are mapped when they are read.

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
| [docs/USER_GUIDE.md](docs/USER_GUIDE.md) | How to register a customer, export, import, and check for updates |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Layout, registration flow, update check, and the launcher icon |
| [docs/DATABASE.md](docs/DATABASE.md) | Drift schema and where the file lives |
| [docs/RELEASING.md](docs/RELEASING.md) | Versioning a release by hand |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Git Flow and pull requests |
| [CHANGELOG.md](CHANGELOG.md) | Version history |
| [SECURITY.md](SECURITY.md) | Reporting vulnerabilities |
| [SUPPORT.md](SUPPORT.md) | Getting help |

## License

[MIT](LICENSE.md) © 2026 AXCEL BLADE
