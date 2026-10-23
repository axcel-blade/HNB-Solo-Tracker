# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- Phone numbers are recorded against the place they were collected. HNB branches record as HNB. Other banks and other companies stay with that organization.
- Built-in directory of HNB branches, other Sri Lankan banks, and finance companies. Custom branches and companies can be added while entering a number or in Settings. Built-in places stay in the list.
- Settings screen for the place lists, a GitHub release check, and the developer credit.
- Update check when the app opens and from Settings. It does not install the update. **View release** opens the GitHub release page.
- Developer credit for Axcel Blade (@axcel-blade) on the main screen and in Settings. The name opens https://github.com/axcel-blade.
- Schema version 2 adds `place` and `organizationKind` on `entries`, and a `places` table. An existing database migrates when it opens.

### Changed
- CSV columns are Phone number, Bank, Place, Kind, Category, Entry date, and Saved date and time. Older five-column CSV files still import.
- JSON backup includes `place` and `organizationKind`. Older backups without those fields still import.
- A CSV duplicate is the same phone, bank, place, category, and entry date.

## [1.0.0] - 2026-10-23

### Changed
- Launcher icon is a blue collection list with three checked rows on Android, iOS, web, Windows, macOS, and Linux.
- Replaced the Windows desktop app with a Flutter app (`hnb_solo_tracker`) for Android, iOS, web, Windows, macOS, and Linux.
- Solo Collection Tracker flow: phone (trimmed, 7–20 characters), entry date, Other Bank or HNB, then Solo Max, Credit/Debit, Other Bank acc, or HNB ACC.
- Count cards for those four categories plus a grand total. Newest-first list, per-row delete, empty state, date-range CSV export, JSON backup, JSON import that replaces after confirmation, CSV import that skips duplicate phone/bank/category/date rows, and clear-all.
- Local storage is Drift 2.35.2 (`solo_collection.sqlite` on native platforms, wasm sqlite in the browser).

The 0.1.0 notes below describe the previous Windows desktop release, not the Flutter app.

## [0.1.0] - 2026-10-21

### Added
- Windows desktop app with a per-user installer and a portable executable.
- Phone entry, HNB / Other Bank, and three product columns with counts.
- Transactions list, CSV export, and a local SQLite file.
- GitHub Actions workflow that published the Windows executable.

[Unreleased]: https://github.com/axcel-blade/HNB-Solo-Tracker/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/axcel-blade/HNB-Solo-Tracker/compare/v0.1.0...v1.0.0
[0.1.0]: https://github.com/axcel-blade/HNB-Solo-Tracker/releases/tag/v0.1.0
