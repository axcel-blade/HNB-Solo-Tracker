# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- Settings tab: staff name and branch (added to CSV exports), phone number length, duplicate handling (allow / warn / block), interface size, default export folder, update check on start-up and "Check now", database backup, open data folder, reset settings.
- `settings` table in the database.

## [0.1.0] - 2026-10-21

### Added
- Windows installer (Inno Setup): per-user install, Start Menu and desktop shortcuts, uninstaller.
- Phone number entry with a two-step pop-up: bank (HNB / Other Bank), then product.
- Three product columns (Solo Max, Solo Credit/Debit Card, Solo Bank Acc) with live counts.
- Count cards with HNB / Other Bank split and a grand total.
- Transactions tab with search and per-entry delete.
- Duplicate-number warning per product.
- CSV export of transactions plus a summary table.
- Local SQLite storage, with a one-time import of the earlier `data.json` file.
- Update check against GitHub Releases at start-up, with in-app download, install and restart.
- GitHub Actions workflow that builds and publishes the Windows `.exe` on version tags.
- HNB colour theme (from hnb.lk), Phosphor icons and an app icon.
- Project documentation and GitHub templates.

[Unreleased]: https://github.com/axcel-blade/HNB-Solo-Tracker/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/axcel-blade/HNB-Solo-Tracker/releases/tag/v0.1.0
