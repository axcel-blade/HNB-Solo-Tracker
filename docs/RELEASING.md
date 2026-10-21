# Releasing

Releases follow Git Flow (see [CONTRIBUTING.md](../CONTRIBUTING.md)) and Semantic Versioning.

1. Create the release branch from `develop`:
   ```bash
   git checkout -b release/X.Y.Z develop
   ```
2. Set `version = "X.Y.Z"` in `Cargo.toml` and run `cargo build` to update `Cargo.lock`.
3. Move the **Unreleased** notes in `CHANGELOG.md` under a new `[X.Y.Z]` heading.
4. Merge into `main`, tag, and push:
   ```bash
   git checkout main
   git merge --no-ff release/X.Y.Z
   git tag vX.Y.Z
   git push origin main --tags
   ```
5. Merge the release branch back into `develop`, then delete it.

Pushing the tag runs `.github/workflows/release.yml`, which builds the app and creates the GitHub release with two files attached:

| File | Purpose |
|---|---|
| `HNB-Solo-Tracker-Setup-vX.Y.Z.exe` | Installer for new users, built from `installer/HNB-Solo-Tracker.iss` |
| `hnb-solo-tracker-vX.Y.Z-windows-x64.exe` | Portable exe; also the file the in-app updater downloads |

Keep the `-windows-x64.exe` name: the updater looks for it.

**The tag must match the version in `Cargo.toml`.** Installed copies compare their own version with the latest release tag and offer the update at start-up.

## Hotfixes

```bash
git checkout -b hotfix/X.Y.Z main
```

Fix the problem, bump the patch version, then merge into both `main` (tag `vX.Y.Z`) and `develop`.
