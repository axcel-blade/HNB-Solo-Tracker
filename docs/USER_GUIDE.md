# User Guide

The window title and the page heading are **HNB Solo Tracker**. The subtitle is **Customer Registration & Lead Analytics Portal**. The header badge shows the released version (`v1.2.0`). The portal uses a dark navy and gold layout. The launcher icon is a blue square with three checked rows.

**Settings** credits **Axcel Blade** and **@axcel-blade**. The profile button opens https://github.com/axcel-blade.

This is an independent tool and is not an official product of Hatton National Bank PLC.

## Add a registration

1. The **Contact / Reference Number** field is focused when the app opens. Type a phone number or a short reference, for example `0771234567` or `Ref #1029`.
2. Under **Bank Provider Category**, choose **HNB Bank** or **Other Bank**.
3. For **HNB Bank**, choose a member status (**Old Active Member** or **New Active Member**) and a product (**SOLO MAX** or **HNB ACC**).
4. For **Other Bank**, choose a payment source. The button reads **Credit / Debit Card** or **Bank Account**. The saved status is `Credit/Debit Card` or `Bank Account`. The product is stored as **External App**. There is no product picker for Other Bank.
5. Under **Acquisition Channel / Location**, choose one channel:
   - **HNB Branch** — pick one of 256 Sri Lankan branches. The Negombo branches are first, then the other named branches, then generated names `HNB Branch Ref #101`, `HNB Branch Ref #102`, and so on until the list reaches 256. The saved detail is that branch name.
   - **Department** — pick an HNB Tower department. The saved detail is `HNB Tower - ` plus the department name. The departments are Cards & Electronic Banking, Digital Banking Solutions, Personal Banking Division, IT & Systems Infrastructure, Marketing & Sales, Customer Experience & Operations, Credit Operations & Risk Management, Compliance & Legal Affairs, Finance & Accounts, and Human Resources Division.
   - **Own Visit** — type a visit, merchant, or field event. If you leave it blank, the saved detail is `Direct Own Visit`.
6. Press **Save Customer Entry**.

The reference is stored after spaces at the ends are removed. Empty text is rejected with “Enter a contact or reference number.” The same message is used when the text is longer than 120 characters. The field itself stops at 120 characters. There is no 7-digit minimum.

The entry date is the local calendar date of the save. The form does not ask for a separate date.

After a save, the reference field and the Own Visit text clear, and the reference field is focused again. The bank, member status, product, payment source, channel, branch, and department stay as you left them. The log and the KPI cards update. A short **Auto-Saved** badge appears.

## Counts

Six cards sit at the top:

| Card | What it counts |
|---|---|
| Total Registrations | Every saved row |
| HNB Members | Bank `HNB`, with the share of all rows to one decimal place (`0` when the log is empty) |
| Other Banks | Bank `Other Bank` |
| Branches | Channel `Branch` |
| HNB Tower Depts | Channel `Department` |
| Own Visits | Channel `Own Visit` |

## Charts

**Bank Provider Ratio** is a doughnut of HNB Bank and Other Bank counts.

**Channel Breakdown (Branch vs Dept vs Own Visit)** is a bar chart of the three channel counts.

## The log

**Recorded Registrations Log** shows the newest row first. Each row has the saved time (or the entry date when no time was stored), the reference, the bank, the member status or payment source, the product, the channel, the channel detail, and a delete button.

**Search entries...** keeps rows whose reference, bank, status, product, channel, or channel detail contains the text. Matching ignores letter case. The filtered rows stay newest first.

**Delete** removes that row and says “Entry removed from log.” It does not ask you to confirm.

When the log has no rows, or the search matches nothing, it says **No entries recorded yet. Use the entry form above to log data.**

## Export

**Export Data** opens **Export Date Filtered Report**. **Start Date** begins as the first day of the current month. **End Date** begins as today. Change either date before you download. Both dates are required. The range includes the start date and the end date.

- **Download CSV** saves `HNB_Solo_Report_<from>_to_<to>.csv`.
- **Download JSON** saves `HNB_Solo_Report_<from>_to_<to>.json`.
- CSV columns: Timestamp, Reference Number, Bank Category, Member Status/Source, Product Type, Channel Type, Channel Detail.
- The timestamp is the UTC time the row was saved. Fields are quoted. The file starts with a UTF-8 BOM so Excel keeps the text. Rows are in the order they were saved, not newest-first.
- JSON is a pretty-printed array of `id`, `timestamp`, `phoneNumber`, `bankType`, `memberStatus`, `productType`, `channelType`, `channelDetail`, and `entryDate` when that date is not empty.
- A row is included when its entry date falls on the start date, the end date, or a day between them. A row with an empty entry date uses the local calendar date of its saved time.
- If the start date is after the end date, the app says “The start date must be before the end date.” and does not export.
- If the range matches nothing, it says “No records found within the selected date range.”
- A successful download says how many entries were exported.

You cannot leave the dates blank to export every row.

## Import

Both import actions are in the export dialog.

**Import JSON** reads a JSON array. A current registration row is kept when the reference is text (1 to 120 characters), the bank is `HNB` or `Other Bank`, the channel is `Branch`, `Department`, or `Own Visit`, the channel detail is text (1 to 240 characters), and the status and product match that bank:

| Bank | Status | Product |
|---|---|---|
| `HNB` | `Old Active Member` or `New Active Member` | `SOLO MAX` or `HNB ACC` |
| `Other Bank` | `Credit/Debit Card` or `Bank Account` | `External App` |

Older collection backups, which use `phone`, `bank`, and `category` instead of those fields, still import. They are mapped into the registration shape:

- A row recorded as HNB (`organizationKind` `hnb`, or bank `HNB` when the kind is not `bank` or `company`) becomes bank `HNB`, status `Old Active Member`, and product `HNB ACC` when the old category is `hnbacc` or “HNB ACC”. Any other HNB category becomes product `SOLO MAX`.
- Any other row becomes bank `Other Bank` and product `External App`. Status is `Credit/Debit Card` when the old category is `card` or “Credit/Debit”, and `Bank Account` otherwise.
- An HNB branch visit (kind `hnb`, or an HNB row that has a place) becomes channel `Branch`. The detail is the place, or `HNB` when the place is empty.
- Every other older row becomes channel `Own Visit`. The detail is the place, or the old bank name when the place is empty, or `Direct Own Visit` when both are empty.

Rows that fail these checks are left out. You must confirm. Confirming replaces every current registration with the valid rows. The place directory in Settings is not replaced.

**Import CSV** reads the export columns. A file from version 1.1.0 (Phone number, Bank, Place, Kind, Category, Entry date, Saved date and time) and a file from version 1.0.0 (Phone number, Bank, Category, Entry date, Saved date and time) still import and are mapped the same way as an older JSON backup. Existing rows stay. A row that matches an existing reference, bank, status, product, channel, channel detail, and timestamp is skipped. Invalid rows are skipped. The toast reports how many rows were imported and how many were skipped.

## Clear everything

**Clear All Data** asks “Delete ALL saved entries from this device? This cannot be undone.” If the log is already empty, it says “There are no entries to clear.” Export a backup first if you still need the registrations. Clearing registrations does not remove the place directory in Settings.

## Settings

**Settings** uses the earlier light layout. It has three sections.

**App update** shows the installed version from the app package. **Check for updates** asks GitHub whether a newer release exists. **Open GitHub releases** opens https://github.com/axcel-blade/HNB-Solo-Tracker/releases.

**Developer** shows Axcel Blade and @axcel-blade. The profile button opens https://github.com/axcel-blade.

**HNB branches**, **Other banks**, and **Other companies** are the place lists from the earlier collection tracker. The registration form does not use them. It uses the 256-branch list and the HNB Tower departments above. You can still add a place here. A name must be 2 to 80 characters. For a bank or company, the organization name is required. Leave the branch blank to store **Head office**. A duplicate name in the same list is refused. An HNB name added on another list is refused. **Remove** deletes a place you added. Built-in places stay. Removing a place does not delete registrations.

## Updates

When the app opens it asks GitHub whether a newer release exists. If a newer version exists, the dialog title is **A new version is available**. **View release** opens that release page. **Later** closes the dialog. The app does not download or install the update.

If GitHub cannot be reached, Settings says so. The registrations are unchanged.

## Where the data lives

See [DATABASE.md](DATABASE.md). Closing the app does not erase registrations.
