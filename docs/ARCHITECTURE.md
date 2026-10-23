# Architecture

HNB Solo Tracker is one Flutter app (`hnb_solo_tracker`) for Android, iOS, web, Windows, macOS, and Linux. The main page is `TrackerScreen`. A two-step dialog asks where the number was collected, then which category to count. **Settings** lists places, checks GitHub for a newer release, and shows the developer credit.

## Technology

| Concern | Choice |
|---|---|
| UI | Flutter, Material 3, Inter via `google_fonts` |
| State | `TrackerStore` (`ChangeNotifier`) holding entries and places |
| Database | Drift 2.35.2 and drift_flutter 0.3.1, schema version 2 |
| Native SQLite | `sqlite3_flutter_libs`, file `solo_collection.sqlite` |
| Web SQLite | `web/sqlite3.wasm` and `web/drift_worker.js` |
| Import and export files | `file_picker` |
| Installed version | `package_info_plus` |
| GitHub release check | `http` against `repos/axcel-blade/HNB-Solo-Tracker/releases/latest` |
| Open a release or profile | `url_launcher` |

The update check runs when the main screen opens and from Settings. It compares the app version with the latest GitHub release tag. A newer tag opens a dialog. **View release** opens that `github.com` page. Nothing is downloaded or installed. Android uses the `INTERNET` permission. macOS debug and release entitlements include `com.apple.security.network.client`.

There is no background sync.

## Layout

```
lib/
  main.dart                      opens the database, store, and GitHub update check
  database/app_database.dart     entries, places, schema version 2
  logic/collection_logic.dart    validation, counts, CSV, JSON
  logic/place_routing.dart       HNB branches record as HNB; other places do not
  models/                        entries, categories, places, built-in directory
  screens/tracker_screen.dart    page, toasts, confirmations, startup update check
  screens/settings_screen.dart   places, update check, developer credit
  services/tracker_store.dart    load and persist through Drift
  services/app_update.dart       version compare and GitHub latest release
  services/release_link.dart     open a https URL
  services/file_exchange.dart    pick and save text files
  theme/app_theme.dart           colours from the reference page
  widgets/                       metrics, list, form, place dialog, update dialog
test/                            logic, places, updates, in-memory Drift, widget flow
android/ ios/ web/ windows/ macos/ linux/
installer/HNB-Solo-Tracker.iss   per-user Windows setup
```

`dart run build_runner build --delete-conflicting-outputs` regenerates `lib/database/app_database.g.dart` after a table change.

## Launcher icon

The mark is three checked collection rows. The field is the app blue `#2463EB`. The checks are navy `#10233F`, the same colours as `AppColors.blue` and `AppColors.navy` in `lib/theme/app_theme.dart`.

| File | Role |
|---|---|
| `assets/icons/app_icon.png` | Full icon for iOS, web, Windows, macOS, and Linux |
| `assets/icons/app_icon_background.png` | Android adaptive background |
| `assets/icons/app_icon_foreground.png` | Android adaptive foreground. Transparent outside the rows so they stay inside the mask |

After editing those files:

```bash
dart run flutter_launcher_icons
```

That writes Android, iOS, web, Windows, and macOS sizes. It does not write the Linux icon. Copy `assets/icons/app_icon.png` to `linux/runner/resources/app_icon.png`.

`windows/runner/resources/app_icon.ico` contains 16, 24, 32, 48, 64, 128, and 256. The command above replaces that file with a single 256 image, so put the smaller sizes back from `app_icon.png` when the artwork changes. The Windows installer uses that `.ico` as the setup icon.

## Saving an entry

1. `checkPhone` trims the value and requires 7–20 characters.
2. The dialog returns a place. `routePlace` records an HNB branch as bank `HNB` and stores the branch name. Another bank or company is recorded under that organization, with its branch or office as the place. A non-HNB organization named HNB is rejected.
3. The second step returns a category id (`max`, `card`, `bank`, `hnbacc`).
4. `TrackerStore.add` appends a `CollectionEntry` (new id, entry date `YYYY-MM-DD`, `createdAt` now, place, organization kind).
5. `AppDatabase.replaceEntries` deletes every entry row and inserts the list again, in order, inside a transaction. Places are stored separately and are not replaced by that write.
6. The UI shows `entries.reversed`, so the newest row is first. Counts only include the four known category ids.

The built-in directory is inserted on load when those places are missing. Custom places are inserted one at a time. Built-in rows cannot be deleted.

Export uses insertion order. CSV import merges in memory and then calls `replaceAll`. JSON import replaces the entry list with the valid backup rows after confirmation.

## Platforms

`AppDatabase.defaults()` calls `driftDatabase(name: 'solo_collection')`.

- Mobile and desktop: Drift opens `solo_collection.sqlite` in the application documents directory.
- Web: the same call passes `DriftWebOptions` for `sqlite3.wasm` and `drift_worker.js`.

Tests pass `NativeDatabase.memory()` into `AppDatabase` so they do not touch the real file.

There is no GitHub Actions workflow in this tree. Analyze and test locally with `flutter analyze` and `flutter test`.
