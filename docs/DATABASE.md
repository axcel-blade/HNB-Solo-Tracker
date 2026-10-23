# Database

Drift (`lib/database/app_database.dart`) owns one table, `entries`. Schema version is 1. The database name passed to `driftDatabase` is `solo_collection`.

## Where it is stored

| Platform | Location |
|---|---|
| Android, iOS, Windows, macOS, Linux | `solo_collection.sqlite` in the application documents directory |
| Windows path | `%USERPROFILE%\Documents\solo_collection.sqlite` |
| Web | Browser storage named `solo_collection`, opened with `web/sqlite3.wasm` and `web/drift_worker.js` |

`shared_preferences` is not used. Web falls back to IndexedDB when the browser cannot use the OPFS worker. Data survives a reload in that browser profile. It does not sync to a server.

Close the native app before copying the sqlite file. On the web, use **Download JSON Backup** if you need a copy you can move.

## Schema

Drift names columns in snake case.

```sql
CREATE TABLE entries (
  local_id    INTEGER PRIMARY KEY AUTOINCREMENT,
  id          TEXT NOT NULL,
  phone       TEXT NOT NULL,
  bank        TEXT NOT NULL,
  category    TEXT NOT NULL,
  entry_date  TEXT NOT NULL,
  created_at  INTEGER
);
```

| Column | Meaning |
|---|---|
| `local_id` | Insert order. The list on screen is this order reversed. |
| `id` | String id used by delete and JSON backup. |
| `phone` | Trimmed text, stored as typed. Not limited to digits. |
| `bank` | `HNB` or `Other Bank` |
| `category` | `max`, `card`, `bank`, or `hnbacc` |
| `entry_date` | `YYYY-MM-DD` from the date picker. May be empty on older imported rows. |
| `created_at` | Drift integer timestamp, or null |

| Category id | Label |
|---|---|
| `max` | Solo Max |
| `card` | Credit/Debit |
| `bank` | Other Bank acc |
| `hnbacc` | HNB ACC |

There is no `settings` table.

## Writes

`replaceEntries` is the only write path: delete all rows, then insert the current list in one transaction. Add, delete, clear, JSON import, and CSV import all go through that.

JSON backup is a pretty-printed array of `{id, phone, bank, category, entryDate, createdAt}`. `createdAt` is omitted when null. Import drops objects that fail the bank and category checks, then replaces the table if you confirm.

CSV duplicate key is phone + bank + category id + entry date.

## Privacy

The file and the browser database contain phone numbers. Treat exports the same way.
