# Security Policy

## Supported versions

| Version | Supported |
|---|---|
| The Flutter app on `develop` / `main` | Yes |
| The 0.1.0 Windows desktop release | No |

When the app opens, and from Settings, it asks GitHub whether a newer release exists. It does not download or install that release.

## Reporting a vulnerability

**Do not open a public issue for security problems.**

Report privately through [GitHub Security Advisories](https://github.com/axcel-blade/HNB-Solo-Tracker/security/advisories/new). Please include:

- A description of the problem and its impact
- Steps to reproduce
- The version from `pubspec.yaml` and the platform you used

You should get a reply within 7 days. Once a fix is released, the advisory is published, with credit to you if you wish.

## Data handling

- Entries are stored only on the device: `solo_collection.sqlite` in the application documents directory, or the browser database `solo_collection` on web. The app does not send them to a server.
- CSV and JSON exports contain contact or reference numbers and the registration fields stored with them. Store and share them according to your data-protection policy.
