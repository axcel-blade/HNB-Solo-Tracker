# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [1.2.0] - 2026-10-24

### Added
- Customer registration form: a contact or reference number, HNB Bank or Other Bank, and an acquisition channel.
- HNB registrations record Old Active Member or New Active Member, and SOLO MAX or HNB ACC.
- Other Bank registrations record Credit/Debit Card or Bank Account. The product is stored as External App.
- HNB Branch channel with 256 Sri Lankan branches. Negombo branches come first, then the other named branches, then generated names such as HNB Branch Ref #101.
- Department channel for the HNB Tower departments. The detail is stored as `HNB Tower - {department}`.
- Own Visit channel. Blank text is stored as Direct Own Visit.
- KPI cards for Total Registrations, HNB Members (with the share of all entries), Other Banks, Branches, HNB Tower Depts, and Own Visits.
- Bank provider ratio chart and channel breakdown chart.
- Searchable registrations log, per-row delete, and Clear All Data after confirmation.
- Export Data dialog. The start and end dates are required and the range is inclusive. Download CSV or JSON from that dialog. Import CSV and Import JSON stay there.
- Schema version 3 adds `bankType`, `memberStatus`, `productType`, `channelType`, and `channelDetail`. Older rows are mapped when they are read.
- Per-user Windows installer `HNB-Solo-Tracker-Setup-1.2.0.exe`.

### Changed
- The portal title is HNB Solo Tracker. The subtitle is Customer Registration & Lead Analytics Portal. The header badge shows v1.2.0. The portal uses the dark navy and gold layout.
- An empty contact or reference is rejected. There is no 7-character minimum. A phone number or a short reference such as Ref #1029 is accepted, up to 120 characters.
- CSV columns are Timestamp, Reference Number, Bank Category, Member Status/Source, Product Type, Channel Type, and Channel Detail. Older collection CSV files still import and are mapped into this shape.
- JSON backup uses those registration fields. Older collection JSON backups still import and are mapped the same way.
- A CSV duplicate is the same reference, bank, member status, product, channel, channel detail, and timestamp.
- The main entry flow no longer uses the place and category dialog. Settings still has the place lists, the GitHub update check, and the developer credit for Axcel Blade (@axcel-blade).

## [1.1.0] - 2026-10-23

### Added
- Phone numbers are recorded against the place they were collected. HNB branches record as HNB. Other banks and other companies stay with that organization.
- Built-in directory of HNB branches, other Sri Lankan banks, and finance companies. Custom branches and companies can be added while entering a number or in Settings. Built-in places stay in the list.
- Settings screen for the place lists, a GitHub release check, and the developer credit.
- Update check when the app opens and from Settings. It does not install the update. **View release** opens the GitHub release page.
- Developer credit for Axcel Blade (@axcel-blade) on the main screen and in Settings. The name opens https://github.com/axcel-blade.
- Schema version 2 adds `place` and `organizationKind` on `entries`, and a `places` table. An existing database migrates when it opens.
- Per-user Windows installer `HNB-Solo-Tracker-Setup-1.1.0.exe`, built with Inno Setup from the Flutter Windows release.

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

[Unreleased]: https://github.com/axcel-blade/HNB-Solo-Tracker/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/axcel-blade/HNB-Solo-Tracker/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/axcel-blade/HNB-Solo-Tracker/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/axcel-blade/HNB-Solo-Tracker/compare/v0.1.0...v1.0.0
[0.1.0]: https://github.com/axcel-blade/HNB-Solo-Tracker/releases/tag/v0.1.0
