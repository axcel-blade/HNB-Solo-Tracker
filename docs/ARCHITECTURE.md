# Architecture

HNB Solo Tracker is one Flutter app (`hnb_solo_tracker`) for Android, iOS, web, Windows, macOS, and Linux. The main page is `TrackerScreen`: a registration form, KPI cards, two charts, and a searchable log. The header badge is the released version (`v1.2.0`). **Settings** lists places, checks GitHub for a newer release, and shows the developer credit. The registration form does not use the place dialog.

This is an independent tool and is not an official product of Hatton National Bank PLC.

## Technology

| Concern | Choice |
|---|---|
| UI | Flutter, Material 3, Inter via `google_fonts`. The portal theme is dark navy and gold (`PortalColors`). Settings still uses the light `AppColors` theme. |
| State | `TrackerStore` (`ChangeNotifier`) holding registrations and places |
| Database | Drift 2.35.2 and drift_flutter 0.3.1, schema version 3 |
| Native SQLite | `sqlite3_flutter_libs`, file `solo_collection.sqlite` |
| Web SQLite | `web/sqlite3.wasm` and `web/drift_worker.js` |
| Import and export files | `file_picker` |
| Installed version | `package_info_plus` (the update check and the Settings version). The header badge is the hardcoded release version. |
| GitHub release check | `http` against `repos/axcel-blade/HNB-Solo-Tracker/releases/latest` |
| Open a release or profile | `url_launcher` |

The update check runs when the main screen opens and from Settings. It compares the app version with the latest GitHub release tag. A newer tag opens a dialog. **View release** opens that `github.com` page. Nothing is downloaded or installed. Android uses the `INTERNET` permission. macOS debug and release entitlements include `com.apple.security.network.client`.

There is no background sync.

## Layout

```
lib/
  main.dart                         opens the database, store, and GitHub update check
  database/app_database.dart        entries, places, schema version 3
  logic/collection_logic.dart       validation, stats, search, CSV, JSON
  logic/place_routing.dart          Settings place rules
  models/registration_catalog.dart  banks, statuses, products, channels, branches, departments
  models/collection_entry.dart      registration row and legacy mapping
  models/                           places, built-in directory, legacy category ids
  screens/tracker_screen.dart       portal, export dialog, toasts, startup update check
  screens/settings_screen.dart      places, update check, developer credit
  services/tracker_store.dart       load and persist through Drift
  services/app_update.dart          version compare and GitHub latest release
  services/release_link.dart        open a https URL
  services/file_exchange.dart       pick and save text files
  theme/app_theme.dart              portal colours and the Settings colours
  widgets/registration_form.dart    customer entry form
  widgets/records_log.dart          searchable log, delete, clear
  widgets/portal_charts.dart        bank ratio and channel bars
  widgets/                          confirm dialog, update dialog, Settings controls
test/                               logic, places, updates, in-memory Drift, widget flow
android/ ios/ web/ windows/ macos/ linux/
installer/HNB-Solo-Tracker.iss      per-user Windows setup
```

`dart run build_runner build --delete-conflicting-outputs` regenerates `lib/database/app_database.g.dart` after a table change.

## Launcher icon

The mark is three checked collection rows. The field is the app blue `#2463EB`. The checks are navy `#10233F`, the same colours as `AppColors.blue` and `AppColors.navy` in `lib/theme/app_theme.dart`. The portal screen uses `PortalColors` (`#002B66` and gold `#FFC72C`) and does not recolour this icon.

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

## Saving a registration

1. `registrationError` trims the reference and rejects empty text and text longer than 120 characters.
2. `registrationFrom` stores HNB or Other Bank. HNB keeps the chosen member status and product (`SOLO MAX` or `HNB ACC`). Other Bank keeps the payment source (`Credit/Debit Card` or `Bank Account`) and sets the product to `External App`.
3. Channel detail is the selected branch, `HNB Tower - {department}`, the Own Visit text, or `Direct Own Visit` when that text is blank. The branch list is `allHnbBranches()` (256 names). Departments are `hnbDepartments`.
4. The entry date is the local calendar date of the save. `createdAt` is the save time.
5. `TrackerStore.add` appends a `CollectionEntry`.
6. `AppDatabase.replaceEntries` deletes every entry row and inserts the list again, in order, inside a transaction. The new columns and the older `bank`, `category`, `place`, and `organization_kind` columns are written together. Places are stored separately and are not replaced by that write.
7. The log shows `newestFirst`, so the newest row is first. Search filters that order. Counts only include the known bank and channel values.

A row whose `bankType` column is empty is mapped in `CollectionEntry.fromLegacy` when it is read. See [DATABASE.md](DATABASE.md).

The Settings place directory is inserted on load when those places are missing. Custom places are inserted one at a time. Built-in rows cannot be deleted. The registration form does not read that directory.

Export uses insertion order inside the inclusive date range. CSV import merges in memory and then calls `replaceAll`. JSON import replaces the registration list with the valid backup rows after confirmation.

## Platforms

`AppDatabase.defaults()` calls `driftDatabase(name: 'solo_collection')`.

- Mobile and desktop: Drift opens `solo_collection.sqlite` in the application documents directory.
- Web: the same call passes `DriftWebOptions` for `sqlite3.wasm` and `drift_worker.js`.

Tests pass `NativeDatabase.memory()` into `AppDatabase` so they do not touch the real file.

There is no GitHub Actions workflow in this tree. Analyze and test locally with `flutter analyze` and `flutter test`.
