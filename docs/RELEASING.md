# Releasing

Releases follow Git Flow in [CONTRIBUTING.md](../CONTRIBUTING.md) and Semantic Versioning. The app version lives in `pubspec.yaml` (`version: X.Y.Z+build` means name `X.Y.Z` and that build number).

There is no GitHub Actions workflow in this repository. A tag does not build or upload anything by itself.

1. Branch from `develop`: `git checkout -b release/X.Y.Z develop`.
2. Set `version: X.Y.Z+build` in `pubspec.yaml`. The build number is higher than the previous release.
3. Move the **Unreleased** notes in `CHANGELOG.md` under a new `[X.Y.Z]` heading.
4. Run `flutter analyze` and `flutter test`.
5. Merge into `main`, tag `vX.Y.Z` on that merge commit, and merge the release branch back into `develop`.
6. Create the GitHub release for that tag and attach the Windows installer. Mark it as the latest release.

Installed copies compare their own version with `https://api.github.com/repos/axcel-blade/HNB-Solo-Tracker/releases/latest` when the app opens and from **Settings**. A newer tag shows **A new version is available**. **View release** opens the GitHub release page. The app does not download or install the file. The tag on the release must be `vX.Y.Z` so that comparison can read it.

## Windows installer

Build the Flutter app, then compile `installer/HNB-Solo-Tracker.iss` with Inno Setup (`ISCC`):

```bash
flutter build windows
iscc /DAppVersion=X.Y.Z installer/HNB-Solo-Tracker.iss
```

The setup executable is `dist/HNB-Solo-Tracker-Setup-X.Y.Z.exe`. It is a per-user installer (`PrivilegesRequired=lowest`). It copies `hnb_solo_tracker.exe`, the Flutter DLLs, and the `data` folder from `build/windows/x64/runner/Release` into `%LOCALAPPDATA%\Programs\HNB Solo Tracker`. It adds a Start Menu shortcut, an uninstaller, and the app icon from `windows/runner/resources/app_icon.ico`. A desktop shortcut is optional. Uninstall leaves `%USERPROFILE%\Documents\solo_collection.sqlite` in place.

Do not commit `dist/` or `build/`. Attach `HNB-Solo-Tracker-Setup-X.Y.Z.exe` to the GitHub release. That is the file users install. The 0.1.0 release also had a portable executable. This Flutter release ships the installer.

Other targets, when you have a machine that can compile them:

| Target | Command |
|---|---|
| Windows app only | `flutter build windows` → `build/windows/x64/runner/Release/hnb_solo_tracker.exe` |
| Web | `flutter build web` |
| Android | `flutter build apk` or `flutter build appbundle` |
| iOS | `flutter build ipa` on macOS |
| macOS | `flutter build macos` on macOS |
| Linux | `flutter build linux` on Linux |

## Hotfixes

```bash
git checkout -b hotfix/X.Y.Z main
```

Fix the problem, bump the patch version in `pubspec.yaml`, then merge into `main` (tag `vX.Y.Z`) and `develop`.
