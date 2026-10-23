# Architecture

HNB Solo Tracker is one Flutter app (`hnb_solo_tracker`) for Android, iOS, web, Windows, macOS, and Linux. The screen is a single page, `TrackerScreen`, with a two-step dialog for bank and category.

## Technology

| Concern | Choice |
|---|---|
| UI | Flutter, Material 3, Inter via `google_fonts` |
| State | `TrackerStore` (`ChangeNotifier`) holding the entry list |
| Database | Drift 2.35.2 and drift_flutter 0.3.1 |
| Native SQLite | `sqlite3_flutter_libs`, file `solo_collection.sqlite` |
| Web SQLite | `web/sqlite3.wasm` and `web/drift_worker.js` |
| Import and export files | `file_picker` |

There is no settings screen, no in-app updater, and no background sync.

## Layout

```
lib/
  main.dart                      opens AppDatabase.defaults() and the store
  database/app_database.dart     Entries table and replace-all writes
  logic/collection_logic.dart    validation, counts, CSV, JSON
  models/                        CollectionEntry, banks, categories
  screens/tracker_screen.dart    page, toasts, confirmations
  services/tracker_store.dart    load and persist through Drift
  services/file_exchange.dart    pick and save text files
  theme/app_theme.dart           colours from the reference page
  widgets/                       metrics, list, form, options dialog
test/                            logic, in-memory Drift, widget flow
android/ ios/ web/ windows/ macos/ linux/
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

`windows/runner/resources/app_icon.ico` contains 16, 24, 32, 48, 64, 128, and 256. The command above replaces that file with a single 256 image, so put the smaller sizes back from `app_icon.png` when the artwork changes.

## Saving an entry

1. `checkPhone` trims the value and requires 7–20 characters.
2. The dialog returns a bank (`HNB` or `Other Bank`) and a category id (`max`, `card`, `bank`, `hnbacc`).
3. `TrackerStore.add` appends a `CollectionEntry` (new id, entry date `YYYY-MM-DD`, `createdAt` now).
4. `AppDatabase.replaceEntries` deletes every row and inserts the list again, in order, inside a transaction.
5. The UI shows `entries.reversed`, so the newest row is first. Counts only include the four known category ids.

Export uses insertion order. CSV import merges in memory and then calls `replaceAll`. JSON import replaces the list with the valid backup rows after confirmation.

## Platforms

`AppDatabase.defaults()` calls `driftDatabase(name: 'solo_collection')`.

- Mobile and desktop: Drift opens `solo_collection.sqlite` in the application documents directory.
- Web: the same call passes `DriftWebOptions` for `sqlite3.wasm` and `drift_worker.js`.

Tests pass `NativeDatabase.memory()` into `AppDatabase` so they do not touch the real file.

There is no GitHub Actions workflow in this tree. Analyze and test locally with `flutter analyze` and `flutter test`.
