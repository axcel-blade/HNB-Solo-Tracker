# Database

Drift (`lib/database/app_database.dart`) owns two tables, `entries` and `places`. Schema version is 3. The database name passed to `driftDatabase` is `solo_collection`.

Opening a version 1 file adds `place` and `organization_kind` on `entries` (empty string by default) and creates `places`. Opening a file older than version 3 adds `bank_type`, `member_status`, `product_type`, `channel_type`, and `channel_detail` (empty string by default). The built-in place directory is inserted the next time the store loads, not inside the migration. Rows with an empty `bank_type` are mapped into the registration shape when they are read. That mapping is not written back until the next time the entry list is saved.

## Where it is stored

| Platform | Location |
|---|---|
| Android, iOS, Windows, macOS, Linux | `solo_collection.sqlite` in the application documents directory |
| Windows path | `%USERPROFILE%\Documents\solo_collection.sqlite` |
| Web | Browser storage named `solo_collection`, opened with `web/sqlite3.wasm` and `web/drift_worker.js` |

`shared_preferences` is not used. Web falls back to IndexedDB when the browser cannot use the OPFS worker. Data survives a reload in that browser profile. It does not sync to a server.

Close the native app before copying the sqlite file. On the web, use **Download JSON** in **Export Data** if you need a copy you can move. The Windows uninstaller does not delete this file.

## Schema

Drift names columns in snake case.

```sql
CREATE TABLE entries (
  local_id           INTEGER PRIMARY KEY AUTOINCREMENT,
  id                 TEXT NOT NULL,
  phone              TEXT NOT NULL,
  bank               TEXT NOT NULL,
  category           TEXT NOT NULL,
  entry_date         TEXT NOT NULL,
  created_at         INTEGER,
  place              TEXT NOT NULL DEFAULT '',
  organization_kind  TEXT NOT NULL DEFAULT '',
  bank_type          TEXT NOT NULL DEFAULT '',
  member_status      TEXT NOT NULL DEFAULT '',
  product_type       TEXT NOT NULL DEFAULT '',
  channel_type       TEXT NOT NULL DEFAULT '',
  channel_detail     TEXT NOT NULL DEFAULT ''
);

CREATE TABLE places (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  kind           TEXT NOT NULL,
  organization   TEXT NOT NULL,
  name           TEXT NOT NULL,
  built_in       INTEGER NOT NULL DEFAULT 0
);
```

| Column | Meaning |
|---|---|
| `local_id` | Insert order. The log on screen is this order reversed. |
| `id` | String id used by delete and JSON backup. |
| `phone` | Contact or reference, trimmed, up to 120 characters. Not limited to digits. |
| `bank` | On a new save, the same value as `bank_type`. On an older row, the organization name. |
| `category` | On a new save, the same value as `product_type`. On an older row, `max`, `card`, `bank`, or `hnbacc`. |
| `entry_date` | `YYYY-MM-DD`. For a new save, the local calendar date of `created_at`. |
| `created_at` | Drift integer timestamp, or null |
| `place` | On a new save, the same value as `channel_detail`. On an older row, the branch or office. |
| `organization_kind` | On a new save, the same value as `channel_type`. On an older row, `hnb`, `bank`, or `company`. |
| `bank_type` | `HNB` or `Other Bank`. Empty on rows saved before schema 3, until they are read and mapped. |
| `member_status` | `Old Active Member`, `New Active Member`, `Credit/Debit Card`, or `Bank Account` |
| `product_type` | `SOLO MAX`, `HNB ACC`, or `External App` |
| `channel_type` | `Branch`, `Department`, or `Own Visit` |
| `channel_detail` | Branch name, `HNB Tower - {department}`, Own Visit text, or `Direct Own Visit` |

| `places.kind` | What it is |
|---|---|
| `hnb` | A branch in the Settings directory. `organization` is `HNB`. |
| `bank` | Another Sri Lankan bank in that directory. |
| `company` | A finance company or other company in that directory. |

`built_in` is 1 for the starter directory and 0 for a place the user added. The registration form does not read `places`. There is no `settings` table. The update check does not write to the database.

## Older rows

`CollectionEntry.fromStored` uses the schema 3 columns when `bank_type` is not empty. Otherwise `fromLegacy` maps the older columns:

- HNB when `organization_kind` is `hnb`, or when `bank` is `HNB` and the kind is not `bank` or `company`. Those rows become bank `HNB`, status `Old Active Member`, and product `HNB ACC` when the category is `hnbacc` (or the label HNB ACC). Any other HNB category becomes product `SOLO MAX`.
- Every other row becomes bank `Other Bank` and product `External App`. Status is `Credit/Debit Card` when the category is `card` (or the label Credit/Debit), and `Bank Account` otherwise.
- Channel `Branch` when the kind is `hnb`, or when the row is HNB and `place` is not empty. The detail is `place`, or `HNB` when `place` is empty.
- Otherwise channel `Own Visit`. The detail is `place`, or `bank` when `place` is empty, or `Direct Own Visit` when both are empty.

Category text is matched to the old ids `max`, `card`, `bank`, and `hnbacc`, or to the old labels Solo Max, Credit/Debit, Other Bank acc, and HNB ACC.

## Writes

`replaceEntries` is the only write path for registration rows: delete all entry rows, then insert the current list in one transaction. Add, delete, clear, JSON import, and CSV import all go through that. Those writes do not change `places`.

Places are inserted when missing built-ins are filled in, and when the user adds a branch or company in Settings. Delete removes a custom place by id. A built-in row is left in place.

JSON backup is a pretty-printed array of `{id, timestamp, phoneNumber, bankType, memberStatus, productType, channelType, channelDetail}` plus `entryDate` when it is not empty. `timestamp` is the UTC `createdAt`, or an empty string when that time is null. Import drops objects that fail the registration checks, or that fail the older bank, category, and kind checks. If you confirm, the valid rows replace the entry table. A backup from schema 1 has no place fields. Those rows import through the mapping above.

CSV columns are Timestamp, Reference Number, Bank Category, Member Status/Source, Product Type, Channel Type, Channel Detail. A duplicate is reference + bank + status + product + channel + channel detail + timestamp (the entry date when there is no timestamp). The version 1.1.0 header (Phone number, Bank, Place, Kind, Category, Entry date, Saved date and time) and the version 1.0.0 header (Phone number, Bank, Category, Entry date, Saved date and time) still import through the same mapping.

## Privacy

The file and the browser database contain contact or reference numbers and the registration fields stored with them. Treat exports the same way.
