import 'dart:async';

import 'package:flutter/material.dart';

import '../logic/collection_logic.dart';
import '../services/app_update.dart';
import '../services/file_exchange.dart';
import '../services/tracker_store.dart';
import '../theme/app_theme.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/portal_charts.dart';
import '../widgets/records_log.dart';
import '../widgets/registration_form.dart';
import '../widgets/update_dialog.dart';
import 'settings_screen.dart';

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({
    super.key,
    required this.store,
    required this.updates,
    this.files = const FileExchange(),
  });

  final TrackerStore store;
  final UpdateChecker updates;
  final FileExchange files;

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  String? _toastTitle;
  String? _toast;
  Timer? _toastTimer;
  var _showSaved = false;
  Timer? _savedTimer;
  var _query = '';
  late DateTime _exportFrom;
  late DateTime _exportTo;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _exportFrom = DateTime(now.year, now.month, 1);
    _exportTo = DateTime(now.year, now.month, now.day);
    widget.store.addListener(_onStore);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_announceUpdate());
    });
  }

  Future<void> _announceUpdate() async {
    final result = await widget.updates.check();
    if (!mounted || result.status != UpdateStatus.available) return;
    await showUpdateDialog(context, result);
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStore);
    _toastTimer?.cancel();
    _savedTimer?.cancel();
    super.dispose();
  }

  void _showToast(String message, {String title = 'Notice'}) {
    _toastTimer?.cancel();
    setState(() {
      _toastTitle = title;
      _toast = message;
    });
    _toastTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _toast = null;
          _toastTitle = null;
        });
      }
    });
  }

  void _pulseSaved() {
    _savedTimer?.cancel();
    setState(() => _showSaved = true);
    _savedTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showSaved = false);
    });
  }

  Future<String?> _save(RegistrationInput input) async {
    final error = registrationError(input);
    if (error != null) {
      _showToast(error);
      return error;
    }
    final entry = registrationFrom(input);
    final saveError = await widget.store.add(
      phone: entry.phone,
      bankType: entry.bankType,
      memberStatus: entry.memberStatus,
      productType: entry.productType,
      channelType: entry.channelType,
      channelDetail: entry.channelDetail,
      entryDate: entry.entryDate,
      createdAt: entry.createdAt,
      id: entry.id,
    );
    if (!mounted) return saveError;
    if (saveError != null) {
      _showToast(saveError);
      return saveError;
    }
    _pulseSaved();
    _showToast(savedMessage, title: 'Saved');
    return null;
  }

  Future<void> _delete(String id) async {
    final error = await widget.store.delete(id);
    if (!mounted) return;
    if (error == null) _pulseSaved();
    _showToast(error ?? deletedMessage, title: error == null ? 'Deleted' : 'Notice');
  }

  Future<void> _clear() async {
    if (widget.store.entries.isEmpty) {
      _showToast(nothingToClearMessage, title: 'Information');
      return;
    }
    final ok = await confirmAction(
      context,
      'Delete ALL saved entries from this device? This cannot be undone.',
    );
    if (!ok || !mounted) return;
    final error = await widget.store.clear();
    if (!mounted) return;
    if (error == null) _pulseSaved();
    _showToast(
      error ?? clearedMessage,
      title: error == null ? 'Data Reset' : 'Notice',
    );
  }

  Future<void> _openExport() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return _ExportDialog(
          from: _exportFrom,
          to: _exportTo,
          onChangeFrom: (value) => setState(() => _exportFrom = value),
          onChangeTo: (value) => setState(() => _exportTo = value),
          onDownload: _download,
          onImportCsv: () {
            Navigator.of(context).pop();
            unawaited(_importCsv());
          },
          onImportJson: () {
            Navigator.of(context).pop();
            unawaited(_importJson());
          },
        );
      },
    );
  }

  Future<void> _download(String format) async {
    final built = buildReport(
      widget.store.entries,
      from: isoDate(_exportFrom),
      to: isoDate(_exportTo),
    );
    if (built.error != null) {
      _showToast(built.error!, title: 'Export Warning');
      return;
    }
    final csv = format == 'csv';
    await _saveFile(
      filename: built.filename(csv ? 'csv' : 'json'),
      contents: csv ? built.csv : built.json,
      extension: csv ? 'csv' : 'json',
      success: 'Exported ${built.count} entries.',
    );
    if (mounted) Navigator.of(context).maybePop();
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
      if (saved) _showToast(success, title: 'Exported');
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
    if (error == null) _pulseSaved();
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
    if (error == null) _pulseSaved();
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

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            SettingsScreen(store: widget.store, updates: widget.updates),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = registrationStats(widget.store.entries);
    return Theme(
      data: buildPortalTheme(),
      child: Scaffold(
        backgroundColor: PortalColors.bg,
        body: Stack(
          children: [
            Column(
              children: [
                _Header(
                  showSaved: _showSaved,
                  onExport: _openExport,
                  onSettings: _openSettings,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Stats(stats: stats),
                            const SizedBox(height: 22),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final stacked = constraints.maxWidth < 980;
                                final form = RegistrationForm(onSave: _save);
                                final charts = _Charts(stats: stats);
                                if (stacked) {
                                  return Column(
                                    children: [
                                      form,
                                      const SizedBox(height: 18),
                                      charts,
                                    ],
                                  );
                                }
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 7, child: form),
                                    const SizedBox(width: 18),
                                    Expanded(flex: 5, child: charts),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 22),
                            RecordsLog(
                              entries: widget.store.entries,
                              query: _query,
                              onQuery: (value) => setState(() => _query = value),
                              onDelete: (entry) => _delete(entry.id),
                              onClear: _clear,
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
                right: 16,
                bottom: 16,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Material(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.info_outline,
                              color: PortalColors.gold,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (_toastTitle ?? 'NOTICE').toUpperCase(),
                                  style: const TextStyle(
                                    color: PortalColors.faint,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _toast!,
                                  style: const TextStyle(
                                    color: PortalColors.text,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() {
                              _toast = null;
                              _toastTitle = null;
                            }),
                            icon: const Icon(Icons.close, size: 16),
                            color: PortalColors.faint,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.showSaved,
    required this.onExport,
    required this.onSettings,
  });

  final bool showSaved;
  final VoidCallback onExport;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PortalColors.blue,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          MediaQuery.paddingOf(context).top + 12,
          16,
          12,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final brandWidth = constraints.maxWidth >= 760
                    ? 460.0
                    : constraints.maxWidth;
            return Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: brandWidth,
                  child: const Row(
                    children: [
                      _SoloMark(),
                      SizedBox(width: 10),
                      Expanded(child: _BrandTitle()),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showSaved) ...[
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0x1A10B981),
                          borderRadius: BorderRadius.all(Radius.circular(99)),
                          border: Border.fromBorderSide(
                            BorderSide(color: Color(0x4D10B981)),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Text(
                            'Auto-Saved',
                            style: TextStyle(
                              color: Color(0xFF34D399),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    TextButton(
                      onPressed: onSettings,
                      child: const Text('Settings'),
                    ),
                    FilledButton.icon(
                      onPressed: onExport,
                      style: FilledButton.styleFrom(
                        backgroundColor: PortalColors.gold,
                        foregroundColor: PortalColors.darkBlue,
                      ),
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('Export Data'),
                    ),
                  ],
                ),
              ],
            );
          },
            ),
          ),
        ),
      ),
    );
  }
}

class _SoloMark extends StatelessWidget {
  const _SoloMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: PortalColors.gold,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'SOLO',
        style: TextStyle(
          color: PortalColors.darkBlue,
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            Text(
              'HNB Solo Tracker',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0x33FFC72C),
                borderRadius: BorderRadius.all(Radius.circular(99)),
                border: Border.fromBorderSide(
                  BorderSide(color: Color(0x55FFC72C)),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Text(
                  'v1.2.0',
                  style: TextStyle(
                    color: PortalColors.gold,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 2),
        Text(
          'Customer Registration & Lead Analytics Portal',
          style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
        ),
      ],
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.stats});

  final RegistrationStats stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 640
            ? 2
            : constraints.maxWidth < 1100
            ? 3
            : 6;
        final cards = [
          _Stat(
            label: 'Total Registrations',
            value: '${stats.total}',
            foot: 'All entries logged',
            valueColor: Colors.white,
          ),
          _Stat(
            label: 'HNB Members',
            value: '${stats.hnb}',
            foot: '${stats.hnbPercent}% of overall entries',
            valueColor: PortalColors.blueStat,
          ),
          _Stat(
            label: 'Other Banks',
            value: '${stats.other}',
            foot: 'Non-HNB Users',
            valueColor: PortalColors.purple,
          ),
          _Stat(
            label: 'Branches',
            value: '${stats.branches}',
            foot: 'Branch-routed',
            valueColor: PortalColors.amber,
          ),
          _Stat(
            label: 'HNB Tower Depts',
            value: '${stats.departments}',
            foot: 'Departmental',
            valueColor: PortalColors.emerald,
          ),
          _Stat(
            label: 'Own Visits',
            value: '${stats.ownVisits}',
            foot: 'Field / Direct',
            valueColor: PortalColors.pink,
          ),
        ];
        return Column(
          children: [
            for (var index = 0; index < cards.length; index += columns) ...[
              if (index > 0) const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var slot = 0; slot < columns; slot++) ...[
                    if (slot > 0) const SizedBox(width: 12),
                    Expanded(
                      child: index + slot < cards.length
                          ? cards[index + slot]
                          : const SizedBox(),
                    ),
                  ],
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.foot,
    required this.valueColor,
  });

  final String label;
  final String value;
  final String foot;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PortalColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PortalColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: PortalColors.faint,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            foot,
            style: const TextStyle(color: PortalColors.faint, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _Charts extends StatelessWidget {
  const _Charts({required this.stats});

  final RegistrationStats stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: PortalColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: PortalColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bank Provider Ratio',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              BankRatioChart(hnb: stats.hnb, other: stats.other),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: PortalColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: PortalColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Channel Breakdown (Branch vs Dept vs Own Visit)',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ChannelBarChart(
                branches: stats.branches,
                departments: stats.departments,
                ownVisits: stats.ownVisits,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExportDialog extends StatelessWidget {
  const _ExportDialog({
    required this.from,
    required this.to,
    required this.onChangeFrom,
    required this.onChangeTo,
    required this.onDownload,
    required this.onImportCsv,
    required this.onImportJson,
  });

  final DateTime from;
  final DateTime to;
  final ValueChanged<DateTime> onChangeFrom;
  final ValueChanged<DateTime> onChangeTo;
  final ValueChanged<String> onDownload;
  final VoidCallback onImportCsv;
  final VoidCallback onImportJson;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildPortalTheme(),
      child: Dialog(
      backgroundColor: PortalColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Export Date Filtered Report',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Specify the starting and ending date range for customer registration entries you wish to include in the downloaded report.',
                style: TextStyle(color: PortalColors.faint, fontSize: 12),
              ),
              const SizedBox(height: 14),
              _DateButton(
                label: 'Start Date',
                value: from,
                onPick: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: from,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) onChangeFrom(picked);
                },
              ),
              const SizedBox(height: 10),
              _DateButton(
                label: 'End Date',
                value: to,
                onPick: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: to,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) onChangeTo(picked);
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Export Format',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => onDownload('csv'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                      ),
                      icon: const Icon(Icons.table_view, size: 16),
                      label: const Text('Download CSV'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => onDownload('json'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                      ),
                      icon: const Icon(Icons.data_object, size: 16),
                      label: const Text('Download JSON'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: onImportCsv, child: const Text('Import CSV')),
                  TextButton(onPressed: onImportJson, child: const Text('Import JSON')),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.onPick,
  });

  final String label;
  final DateTime value;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: PortalColors.muted)),
        const SizedBox(height: 4),
        OutlinedButton(
          onPressed: onPick,
          style: OutlinedButton.styleFrom(
            foregroundColor: PortalColors.text,
            side: const BorderSide(color: PortalColors.inputBorder),
            alignment: Alignment.centerLeft,
          ),
          child: Text(isoDate(value)),
        ),
      ],
    );
  }
}
