# User Guide

The window title is **HNB Solo Tracker**. The page heading is **Solo Collection Tracker**. The launcher icon is a blue square with three checked rows.

## Add an entry

1. The **Phone number** field is focused when the app opens. Type the number, for example `0771234567`.
2. Pick an **Entry date**. Today is selected already. Use the calendar to record a past date.
3. Press **Continue to options →**.
4. **Step 1 of 2:** choose **Other Bank** or **HNB**, then **Next →**.
5. **Step 2 of 2:** choose **Solo Max**, **Credit/Debit**, **Other Bank acc**, or **HNB ACC**, then **Save entry ✓**.

The phone is stored exactly as entered, after spaces at the ends are removed. It must be 7 to 20 characters. A shorter number shows “Please check the phone number and try again.” An empty number does nothing.

After a save, the phone field clears, the date returns to today, and the list and counts update. **Cancel** closes the dialog. **← Back** returns from the category step to the bank step.

## Counts

Five cards sit at the top:

| Card | What it counts |
|---|---|
| Solo Max | Category `max` |
| Credit/Debit | Category `card` |
| Other Bank acc | Category `bank` |
| HNB ACC | Category `hnbacc` |
| Grand Total | Those four counts added together |

## The list

**Collection entries** shows the newest row first. Each row has the phone number, a bank tag, the category name, the entry date, and **Delete**.

**Delete** asks “Delete this entry?” and removes that row.

When there are no rows, the list says **No entries yet**.

## Export

Set **Export from date** and **Export to date**, or leave both empty to export every row. Press **Export selected dates**.

- The file is `solo-collection-<from>-to-<to>.csv` (`all` when a date is blank).
- Columns: Phone number, Bank, Category, Entry date, Saved date and time.
- Fields are quoted so Excel keeps the text. Rows are in the order they were saved, not newest-first.
- If the start date is after the end date, the app says so and does not export.
- If the range matches nothing, it says no entries were found.

**Download JSON Backup** saves `solo-collection-backup-<UTC date>.json` with the current rows.

## Import

**Import JSON backup** reads a JSON array. A row is kept only when the phone is text, the bank is `HNB` or `Other Bank`, and the category is `max`, `card`, `bank`, or `hnbacc`. You must confirm. Confirming replaces every current entry with those valid rows.

**Import CSV** reads the export columns (category may be the display name or the id). Existing rows stay. A row that matches an existing phone, bank, category, and entry date is skipped. Invalid rows are skipped.

## Clear everything

**Clear all entries** asks you to confirm. If the list is already empty, it says there is nothing to clear. Export a backup first if you still need the numbers.

## Where the data lives

See [DATABASE.md](DATABASE.md). Closing the app does not erase entries.
