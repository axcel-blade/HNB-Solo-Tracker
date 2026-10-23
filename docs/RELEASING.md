# Releasing

Releases follow Git Flow in [CONTRIBUTING.md](../CONTRIBUTING.md) and Semantic Versioning. The app version lives in `pubspec.yaml` (`version: 1.0.0+1` means name `1.0.0`, build number `1`).

There is no GitHub Actions workflow in this repository. A tag does not build or upload anything by itself.

1. Branch from `develop`: `git checkout -b release/X.Y.Z develop`.
2. Set `version: X.Y.Z+build` in `pubspec.yaml`.
3. Move the **Unreleased** notes in `CHANGELOG.md` under a new `[X.Y.Z]` heading.
4. Run `flutter analyze` and `flutter test`.
5. Merge into `main`, tag `vX.Y.Z`, and merge the release branch back into `develop`.

Build the artifacts you intend to ship on a machine that can compile that target:

| Target | Command |
|---|---|
| Windows | `flutter build windows` → `build/windows/x64/runner/Release/hnb_solo_tracker.exe` |
| Web | `flutter build web` |
| Android | `flutter build apk` or `flutter build appbundle` |
| iOS | `flutter build ipa` on macOS |
| macOS | `flutter build macos` on macOS |
| Linux | `flutter build linux` on Linux |

Attach those files to the GitHub release yourself. The app does not check for updates.

## Hotfixes

```bash
git checkout -b hotfix/X.Y.Z main
```

Fix the problem, bump the patch version in `pubspec.yaml`, then merge into `main` (tag `vX.Y.Z`) and `develop`.
