<p align="center">
  <img src="assets/icon.png" width="96" alt="HNB Solo Tracker icon">
</p>

<h1 align="center">HNB Solo Tracker</h1>

<p align="center">
  A fast Windows desktop app for logging and counting HNB Solo sign-ups.<br>
  Built with Rust, egui and SQLite.
</p>

<p align="center">
  <a href="https://github.com/axcel-blade/HNB-Solo-Tracker/releases/latest"><img src="https://img.shields.io/github/v/release/axcel-blade/HNB-Solo-Tracker" alt="Latest release"></a>
  <a href="https://github.com/axcel-blade/HNB-Solo-Tracker/actions/workflows/ci.yml"><img src="https://github.com/axcel-blade/HNB-Solo-Tracker/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <img src="https://img.shields.io/badge/platform-Windows-0060AF" alt="Windows">
  <img src="https://img.shields.io/badge/rust-stable-00A2E8" alt="Rust">
  <a href="LICENSE.md"><img src="https://img.shields.io/badge/license-MIT-2C2F31" alt="MIT"></a>
</p>

---

## Features

- **Three-step entry**: type a phone number, pick the bank, pick the product. Works from the keyboard alone (`Enter`, `1`/`2`/`3`, `Esc`, `Backspace`).
- **Three columns**: Solo Max, Solo Credit/Debit Card and Solo Bank Acc, each with a live count.
- **Count cards**: totals per product with an HNB / Other Bank split, plus a grand total.
- **Transactions log**: every entry with date and time, searchable by phone number, with delete.
- **Duplicate warning**: flags a number already recorded under the same product.
- **CSV export**: all transactions plus a summary table; leading zeros are kept in Excel.
- **Local SQLite storage**: nothing leaves your PC.
- **Auto-update**: checks GitHub Releases at start-up and installs new versions in one click.
- **HNB look**: colours taken from [hnb.lk](https://www.hnb.lk/), Phosphor icons.

## Install

**Installer (recommended):** download `HNB-Solo-Tracker-Setup-vX.Y.Z.exe` from [Releases](https://github.com/axcel-blade/HNB-Solo-Tracker/releases/latest) and run it. It installs for the current user (no admin rights needed), adds Start Menu and optional desktop shortcuts, and can be removed from **Settings → Apps**.

**Portable:** download `hnb-solo-tracker-vX.Y.Z-windows-x64.exe` and run it from anywhere.

Windows SmartScreen may warn about an unsigned app the first time; choose **More info → Run anyway**.

## Usage

1. Type a phone number (9–12 digits) and press **Enter**.
2. Choose **HNB** or **Other Bank** (click, or press `1` / `2`).
3. Choose **Solo Max**, **Solo Credit/Debit Card** or **Solo Bank Acc** (click, or press `1` / `2` / `3`).

The number appears in the matching column and the counts update. Use **Export CSV** to save a report.

## Data location

| Item | Path |
|---|---|
| Database | `%APPDATA%\HNB Solo Tracker\hnb_solo_tracker.db` |

See [docs/DATABASE.md](docs/DATABASE.md) for the schema.

## Build from source

```bash
cargo build --release
```

The executable is written to `target/release/hnb-solo-tracker.exe`.

## Documentation

| Document | Description |
|---|---|
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | How the app is structured |
| [docs/DATABASE.md](docs/DATABASE.md) | SQLite schema and queries |
| [docs/RELEASING.md](docs/RELEASING.md) | Publishing a new version |
| [docs/USER_GUIDE.md](docs/USER_GUIDE.md) | Step-by-step guide for staff |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Branching (Git Flow) and pull requests |
| [CHANGELOG.md](CHANGELOG.md) | Version history |
| [SECURITY.md](SECURITY.md) | Reporting vulnerabilities |
| [SUPPORT.md](SUPPORT.md) | Getting help |

## License

[MIT](LICENSE.md) © 2026 AXCEL BLADE

> This is an independent tool and is not an official product of Hatton National Bank PLC.
