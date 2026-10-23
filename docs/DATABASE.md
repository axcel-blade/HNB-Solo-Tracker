# Database

Drift (`lib/database/app_database.dart`) owns two tables, `entries` and `places`. Schema version is 2. The database name passed to `driftDatabase` is `solo_collection`.

Opening a version 1 file adds `place` and `organization_kind` on `entries` (empty string by default) and creates `places`. The built-in directory is inserted the next time the store loads, not inside the migration.

## Where it is stored

| Platform | Location |
|---|---|
| Android, iOS, Windows, macOS, Linux | `solo_collection.sqlite` in the application documents directory |
| Windows path | `%USERPROFILE%\Documents\solo_collection.sqlite` |
| Web | Browser storage named `solo_collection`, opened with `web/sqlite3.wasm` and `web/drift_worker.js` |

`shared_preferences` is not used. Web falls back to IndexedDB when the browser cannot use the OPFS worker. Data survives a reload in that browser profile. It does not sync to a server.

Close the native app before copying the sqlite file. On the web, use **Download JSON Backup** if you need a copy you can move. The Windows uninstaller does not delete this file.

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
  organization_kind  TEXT NOT NULL DEFAULT ''
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
| `local_id` | Insert order. The list on screen is this order reversed. |
| `id` | String id used by delete and JSON backup. |
| `phone` | Trimmed text, stored as typed. Not limited to digits. |
| `bank` | `HNB` for an HNB branch. For every other place, the organization name. |
| `category` | `max`, `card`, `bank`, or `hnbacc` |
| `entry_date` | `YYYY-MM-DD` from the date picker. May be empty on older imported rows. |
| `created_at` | Drift integer timestamp, or null |
| `place` | Branch or office name. Empty on rows saved before schema 2. |
| `organization_kind` | `hnb`, `bank`, or `company`. Empty on older rows. |

| Category id | Label |
|---|---|
| `max` | Solo Max |
| `card` | Credit/Debit |
| `bank` | Other Bank acc |
| `hnbacc` | HNB ACC |

| `places.kind` | What it is |
|---|---|
| `hnb` | Hatton National Bank branch. `organization` is `HNB`. Recorded as HNB. |
| `bank` | Another Sri Lankan bank. Recorded as that bank’s name. |
| `company` | A finance company or other company. Recorded as that company’s name. |

`built_in` is 1 for the starter directory and 0 for a place the user added. There is no `settings` table. The update check does not write to the database.

## Writes

`replaceEntries` is the only write path for collection rows: delete all entry rows, then insert the current list in one transaction. Add, delete, clear, JSON import, and CSV import all go through that. Those writes do not change `places`.

Places are inserted when missing built-ins are filled in, and when the user adds a branch or company. Delete removes a custom place by id. A built-in row is left in place.

JSON backup is a pretty-printed array of `{id, phone, bank, category, entryDate, place, organizationKind, createdAt}`. `createdAt` is omitted when null. Import drops objects that fail the bank, category, and kind checks, then replaces the entry table if you confirm. A backup from schema 1 has no place fields; those rows import with an empty place.

CSV columns are Phone number, Bank, Place, Kind, Category, Entry date, Saved date and time. A duplicate is phone + bank + place + category id + entry date. The older header without Place and Kind still imports.

## Privacy

The file and the browser database contain phone numbers and the places they were collected. Treat exports the same way.
