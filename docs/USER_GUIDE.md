# User Guide

The window title is **HNB Solo Tracker**. The page heading is **Solo Collection Tracker**. The launcher icon is a blue square with three checked rows.

The footer says **Developed by Axcel Blade · @axcel-blade**. That name opens https://github.com/axcel-blade. The same credit is in **Settings**.

## Add an entry

1. The **Phone number** field is focused when the app opens. Type the number, for example `0771234567`.
2. Pick an **Entry date**. Today is selected already. Use the calendar to record a past date.
3. Under **Collection site**, press **Choose place**. After a place is chosen, the panel says **Collecting at** and **Change place** opens the same list.
4. **Step 1 of 2 — Where was this number collected?** Pick **HNB branches**, **Other banks**, or **Other companies**. Search by branch or organization name.
5. Select a row. The subtitle says what the number will be recorded as. Press **Next →**.
6. **Step 2 of 2:** choose **Solo Max**, **Credit/Debit**, **Other Bank acc**, or **HNB ACC**, then **Save entry ✓**.

HNB branches are the only places recorded as **HNB**. A number collected at another bank or company stays with that organization. The same branch name under another bank is not treated as HNB.

The phone is stored exactly as entered, after spaces at the ends are removed. It must be 7 to 20 characters. A shorter number shows “Please check the phone number and try again.” An empty number does nothing.

After a save, the phone field clears, the date returns to today, and the list and counts update. The chosen place stays so the next number can use it. **Cancel** closes the dialog. **← Back** returns from the category step to the place step.

## Places

The app starts with a directory of HNB branches, other Sri Lankan banks, and finance companies. Other banks and companies are listed at **Head office** until you add a branch or office.

On the place step, **Add HNB branch**, **Add bank branch**, or **Add company** asks for a name of 2 to 80 characters. For a bank or company, the organization name is required. Leave the branch blank to store **Head office**. A duplicate name in the same list is refused. An HNB name added on another tab is refused: those branches belong on **HNB branches**.

**Settings** shows the three lists. **Remove** deletes a place you added. Built-in places stay. Removing a place does not delete numbers already saved there.

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

**Collection entries** shows the newest row first. Each row has the phone number, the recorded organization (**HNB** or the other bank or company), the place when one was stored, the category name, the entry date, and **Delete**.

**Delete** asks “Delete this entry?” and removes that row.

When there are no rows, the list says **No entries yet**.

## Export

Set **Export from date** and **Export to date**, or leave both empty to export every row. Press **Export selected dates**.

- The file is `solo-collection-<from>-to-<to>.csv` (`all` when a date is blank).
- Columns: Phone number, Bank, Place, Kind, Category, Entry date, Saved date and time.
- **Bank** is `HNB` or the other organization. **Place** is the branch or office. **Kind** is `hnb`, `bank`, or `company`.
- Fields are quoted so Excel keeps the text. Rows are in the order they were saved, not newest-first.
- If the start date is after the end date, the app says so and does not export.
- If the range matches nothing, it says no entries were found.

**Download JSON Backup** saves `solo-collection-backup-<UTC date>.json` with the current rows, including `place` and `organizationKind`.

## Import

**Import JSON backup** reads a JSON array. A row is kept only when the phone is text, the bank is text (up to 80 characters), and the category is `max`, `card`, `bank`, or `hnbacc`. `organizationKind`, when present, must be `hnb`, `bank`, or `company`. An `hnb` row must be bank `HNB`. A `bank` or `company` row must not be bank `HNB`. Older backups without a place still import. You must confirm. Confirming replaces every current entry with those valid rows.

**Import CSV** reads the export columns (category may be the display name or the id). A file from version 1.0.0, with no Place or Kind columns, still imports. Existing rows stay. A row that matches an existing phone, bank, place, category, and entry date is skipped. Invalid rows are skipped.

## Clear everything

**Clear all entries** asks you to confirm. If the list is already empty, it says there is nothing to clear. Export a backup first if you still need the numbers. Clearing entries does not remove the place directory.

## Updates

When the app opens it asks GitHub whether a newer release exists. **Settings** shows the installed version and **Check for updates** runs the same check. **Open GitHub releases** opens https://github.com/axcel-blade/HNB-Solo-Tracker/releases.

If a newer version exists, the dialog title is **A new version is available**. **View release** opens that release page. **Later** closes the dialog. The app does not download or install the update.

If GitHub cannot be reached, Settings says so. The collection entries are unchanged.

## Where the data lives

See [DATABASE.md](DATABASE.md). Closing the app does not erase entries.
