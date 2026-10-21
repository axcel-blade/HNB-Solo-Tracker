# Security Policy

## Supported versions

| Version | Supported |
|---|---|
| Latest release | Yes |
| Older releases | No. Please update (the app offers updates at start-up). |

## Reporting a vulnerability

**Do not open a public issue for security problems.**

Report privately through [GitHub Security Advisories](https://github.com/axcel-blade/HNB-Solo-Tracker/security/advisories/new). Please include:

- A description of the problem and its impact
- Steps to reproduce
- The app version (shown in the bottom bar)

You should get a reply within 7 days. Once a fix is released, the advisory is published, with credit to you if you wish.

## Data handling

- All data is stored locally in SQLite under `%APPDATA%\HNB Solo Tracker`. Nothing is sent to any server.
- The only network requests go to `api.github.com` and `github.com`, to check for and download updates.
- Downloaded updates are checked to be a valid Windows executable before they replace the app.
- Exported CSV files contain customer phone numbers. Store and share them according to your bank's data-protection policy.
