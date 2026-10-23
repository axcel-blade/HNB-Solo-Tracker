import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'app_button.dart';
import 'labeled_field.dart';

class AddPanel extends StatelessWidget {
  const AddPanel({
    super.key,
    required this.phoneController,
    required this.phoneFocus,
    required this.entryDate,
    required this.exportFrom,
    required this.exportTo,
    required this.onPickEntryDate,
    required this.onPickExportFrom,
    required this.onPickExportTo,
    required this.onClearExportFrom,
    required this.onClearExportTo,
    required this.onContinue,
    required this.onExport,
    required this.onJsonBackup,
    required this.onImportCsv,
    required this.onImportJson,
    required this.onClear,
  });

  final TextEditingController phoneController;
  final FocusNode phoneFocus;
  final DateTime entryDate;
  final DateTime? exportFrom;
  final DateTime? exportTo;
  final VoidCallback onPickEntryDate;
  final VoidCallback onPickExportFrom;
  final VoidCallback onPickExportTo;
  final VoidCallback onClearExportFrom;
  final VoidCallback onClearExportTo;
  final VoidCallback onContinue;
  final VoidCallback onExport;
  final VoidCallback onJsonBackup;
  final VoidCallback onImportCsv;
  final VoidCallback onImportJson;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: panelDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 19, 20, 19),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.line)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add a collection',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 4),
                Text(
                  'Enter a phone number and date, then choose the options.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LabeledField(
                  label: 'Phone number',
                  hint: 'Numbers are stored exactly as entered.',
                  child: TextField(
                    controller: phoneController,
                    focusNode: phoneFocus,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    maxLength: 20,
                    inputFormatters: [LengthLimitingTextInputFormatter(20)],
                    buildCounter:
                        (
                          context, {
                          required currentLength,
                          required isFocused,
                          maxLength,
                        }) => null,
                    decoration: appInputDecoration(hint: 'e.g. 0771234567'),
                    onSubmitted: (_) => onContinue(),
                  ),
                ),
                DateField(
                  label: 'Entry date',
                  hint: 'Use the calendar to add a past entry.',
                  value: entryDate,
                  onPick: onPickEntryDate,
                ),
                AppButton(
                  label: 'Continue to options →',
                  expand: true,
                  onPressed: onContinue,
                ),
                const SizedBox(height: 15),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.noticeBg,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Your entries are saved automatically on this device. Export a backup regularly if the information is important.',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Divider(height: 1, thickness: 1, color: AppColors.line),
                ),
                DateField(
                  label: 'Export from date',
                  value: exportFrom,
                  placeholder: 'Any date',
                  onPick: onPickExportFrom,
                  onClear: exportFrom == null ? null : onClearExportFrom,
                ),
                DateField(
                  label: 'Export to date',
                  value: exportTo,
                  placeholder: 'Any date',
                  onPick: onPickExportTo,
                  onClear: exportTo == null ? null : onClearExportTo,
                ),
                AppButton(
                  label: 'Export selected dates',
                  expand: true,
                  onPressed: onExport,
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: [
                    AppButton(
                      label: 'Download JSON Backup',
                      kind: AppButtonKind.outline,
                      onPressed: onJsonBackup,
                    ),
                    AppButton(
                      label: 'Import CSV',
                      kind: AppButtonKind.outline,
                      onPressed: onImportCsv,
                    ),
                    AppButton(
                      label: 'Import JSON backup',
                      kind: AppButtonKind.outline,
                      onPressed: onImportJson,
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                const Text(
                  'Choose a date range to export only those entries. Leave both dates blank to export all records. CSV opens in Excel. Import keeps existing records and skips matching duplicates.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Divider(height: 1, thickness: 1, color: AppColors.line),
                ),
                AppButton(
                  label: 'Clear all entries',
                  kind: AppButtonKind.danger,
                  expand: true,
                  onPressed: onClear,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
