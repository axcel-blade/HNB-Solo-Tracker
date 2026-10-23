import 'dart:async';

import 'package:flutter/material.dart';

import '../logic/collection_logic.dart';
import '../services/file_exchange.dart';
import '../services/tracker_store.dart';
import '../theme/app_theme.dart';
import '../widgets/add_panel.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/entries_panel.dart';
import '../widgets/metric_card.dart';
import '../widgets/options_dialog.dart';

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({
    super.key,
    required this.store,
    this.files = const FileExchange(),
  });

  final TrackerStore store;
  final FileExchange files;

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  final _phoneController = TextEditingController();
  final _phoneFocus = FocusNode();
  late DateTime _entryDate;
  DateTime? _exportFrom;
  DateTime? _exportTo;
  String? _toast;
  Timer? _toastTimer;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _entryDate = DateTime(now.year, now.month, now.day);
    widget.store.addListener(_onStore);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _phoneFocus.requestFocus();
    });
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStore);
    _phoneController.dispose();
    _phoneFocus.dispose();
    _toastTimer?.cancel();
    super.dispose();
  }

  void _showToast(String message) {
    _toastTimer?.cancel();
    setState(() => _toast = message);
    _toastTimer = Timer(const Duration(milliseconds: 2600), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  Future<DateTime?> _pickDate(DateTime initial) {
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
  }

  Future<void> _continue() async {
    final check = checkPhone(_phoneController.text);
    if (check == PhoneCheck.empty) return;
    if (check == PhoneCheck.tooShort) {
      _showToast(phoneTooShortMessage);
      return;
    }
    final phone = _phoneController.text.trim();
    final selection = await showOptionsDialog(context, phone);
    if (selection == null || !mounted) return;
    final error = await widget.store.add(
      phone: phone,
      bank: selection.bank,
      category: selection.category,
      entryDate: isoDate(_entryDate),
    );
    if (!mounted) return;
    if (error != null) {
      _showToast(error);
      return;
    }
    _phoneController.clear();
    final now = DateTime.now();
    setState(() => _entryDate = DateTime(now.year, now.month, now.day));
    _phoneFocus.requestFocus();
    _showToast('Entry saved automatically.');
  }

  Future<void> _delete(String id) async {
    final ok = await confirmAction(context, 'Delete this entry?');
    if (!ok || !mounted) return;
    final error = await widget.store.delete(id);
    if (!mounted) return;
    _showToast(error ?? 'Entry deleted.');
  }

  Future<void> _clear() async {
    if (widget.store.entries.isEmpty) {
      _showToast('There are no entries to clear.');
      return;
    }
    final ok = await confirmAction(
      context,
      'Delete ALL saved entries from this device? This cannot be undone. Export a backup first if needed.',
    );
    if (!ok || !mounted) return;
    final error = await widget.store.clear();
    if (!mounted) return;
    _showToast(error ?? 'All entries cleared.');
  }

  Future<void> _export() async {
    final built = buildExport(
      widget.store.entries,
      from: _exportFrom == null ? '' : isoDate(_exportFrom!),
      to: _exportTo == null ? '' : isoDate(_exportTo!),
    );
    if (built.error != null) {
      _showToast(built.error!);
      return;
    }
    await _saveFile(
      filename: built.filename!,
      contents: built.csv!,
      extension: 'csv',
      success: 'Exported ${built.count} entries.',
    );
  }

  Future<void> _backup() async {
    await _saveFile(
      filename: jsonBackupFilename(DateTime.now()),
      contents: encodeBackup(widget.store.entries),
      extension: 'json',
      success: 'JSON backup downloaded (${widget.store.entries.length} records).',
    );
  }

  Future<void> _saveFile({
    required String filename,
    required String contents,
    required String extension,
    required String success,
  }) async {
    try {
      final saved = await widget.files.saveText(
        filename: filename,
        contents: contents,
        extension: extension,
      );
      if (!mounted) return;
      if (saved) _showToast(success);
    } catch (_) {
      if (mounted) _showToast('Could not save the file.');
    }
  }

  Future<void> _importJson() async {
    final text = await _pick('json');
    if (text == null || !mounted) return;
    final parsed = parseBackup(text);
    if (parsed == null) {
      _showToast(invalidJsonMessage);
      return;
    }
    final ok = await confirmAction(
      context,
      'Import ${parsed.length} valid entries? This will replace the current entries.',
    );
    if (!ok || !mounted) return;
    final error = await widget.store.replaceAll(parsed);
    if (!mounted) return;
    _showToast(error ?? 'Backup imported.');
  }

  Future<void> _importCsv() async {
    final text = await _pick('csv');
    if (text == null || !mounted) return;
    final result = mergeCsv(widget.store.entries, text);
    if (result.imported == 0) {
      _showToast(result.message);
      return;
    }
    final error = await widget.store.replaceAll(result.entries);
    if (!mounted) return;
    _showToast(error ?? result.message);
  }

  Future<String?> _pick(String extension) async {
    try {
      return await widget.files.pickText([extension]);
    } catch (_) {
      if (mounted) _showToast('Could not read that file.');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final counts = countEntries(widget.store.entries);
    final viewport = MediaQuery.sizeOf(context).width;
    final narrowTitle = viewport <= 480;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Column(
            children: [
              _Header(narrowTitle: narrowTitle),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 48),
                  child: _frame(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 26),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Metrics(counts: counts, viewport: viewport),
                          const SizedBox(height: 22),
                          if (viewport <= 800)
                            Column(
                              children: [
                                EntriesPanel(
                                  entries: widget.store.entries,
                                  onDelete: (entry) => _delete(entry.id),
                                ),
                                const SizedBox(height: 18),
                                _addPanel(),
                              ],
                            )
                          else
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: EntriesPanel(
                                    entries: widget.store.entries,
                                    onDelete: (entry) => _delete(entry.id),
                                  ),
                                ),
                                const SizedBox(width: 18),
                                SizedBox(width: 340, child: _addPanel()),
                              ],
                            ),
                          const SizedBox(height: 20),
                          const Text(
                            'Solo Collection Tracker · Keep your data private and backed up.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_toast != null)
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: IgnorePointer(
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.toast,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 28,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      child: Text(
                        _toast!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  AddPanel _addPanel() {
    return AddPanel(
      phoneController: _phoneController,
      phoneFocus: _phoneFocus,
      entryDate: _entryDate,
      exportFrom: _exportFrom,
      exportTo: _exportTo,
      onPickEntryDate: () async {
        final picked = await _pickDate(_entryDate);
        if (picked != null) {
          setState(() => _entryDate = DateTime(picked.year, picked.month, picked.day));
        }
      },
      onPickExportFrom: () async {
        final picked = await _pickDate(_exportFrom ?? DateTime.now());
        if (picked != null) setState(() => _exportFrom = picked);
      },
      onPickExportTo: () async {
        final picked = await _pickDate(_exportTo ?? DateTime.now());
        if (picked != null) setState(() => _exportTo = picked);
      },
      onClearExportFrom: () => setState(() => _exportFrom = null),
      onClearExportTo: () => setState(() => _exportTo = null),
      onContinue: _continue,
      onExport: _export,
      onJsonBackup: _backup,
      onImportCsv: _importCsv,
      onImportJson: _importJson,
      onClear: _clear,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.narrowTitle});

  final bool narrowTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.5, -1),
          end: Alignment(0.7, 1),
          colors: [AppColors.navy, AppColors.headerEnd],
        ),
      ),
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 25),
        child: _frame(
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 15,
            runSpacing: 12,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'S',
                        style: TextStyle(
                          color: AppColors.headerEnd,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Solo Collection Tracker',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: narrowTitle ? 18 : 21,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Simple, organised entry tracking',
                            style: TextStyle(
                              color: AppColors.subtitle,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                '● Autosave is on · Saved on this device',
                style: TextStyle(color: AppColors.privacy, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metrics extends StatelessWidget {
  const _Metrics({required this.counts, required this.viewport});

  final CategoryCounts counts;
  final double viewport;

  @override
  Widget build(BuildContext context) {
    final columns = viewport <= 480 ? 1 : viewport <= 800 ? 2 : 5;
    final compact = viewport <= 800;
    final gap = compact ? 8.0 : 14.0;
    final cards = [
      MetricCard(
        label: 'Solo Max',
        foot: 'Total entries',
        value: counts.max,
        compact: compact,
        horizontal: columns == 1,
      ),
      MetricCard(
        label: 'Credit/Debit',
        foot: 'Total entries',
        value: counts.card,
        compact: compact,
        horizontal: columns == 1,
      ),
      MetricCard(
        label: 'Other Bank acc',
        foot: 'Total entries',
        value: counts.bank,
        compact: compact,
        horizontal: columns == 1,
      ),
      MetricCard(
        label: 'HNB ACC',
        foot: 'Total entries',
        value: counts.hnbAcc,
        compact: compact,
        horizontal: columns == 1,
      ),
      MetricCard(
        label: 'Grand Total',
        foot: 'All categories combined',
        value: counts.total,
        compact: compact,
        horizontal: columns == 1,
      ),
    ];
    final rows = <Widget>[];
    for (var index = 0; index < cards.length; index += columns) {
      final end = index + columns > cards.length ? cards.length : index + columns;
      final slice = cards.sublist(index, end);
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var slot = 0; slot < columns; slot++) ...[
              if (slot > 0) SizedBox(width: gap),
              Expanded(child: slot < slice.length ? slice[slot] : const SizedBox()),
            ],
          ],
        ),
      );
    }
    return Column(
      children: [
        for (var index = 0; index < rows.length; index++) ...[
          if (index > 0) SizedBox(height: gap),
          rows[index],
        ],
      ],
    );
  }
}

Widget _frame({required Widget child}) {
  return Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1120),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: child,
      ),
    ),
  );
}
