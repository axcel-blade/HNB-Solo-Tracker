import 'package:flutter/material.dart';

import '../logic/collection_logic.dart';
import '../models/collection_entry.dart';
import '../models/registration_catalog.dart';
import '../theme/app_theme.dart';

class RecordsLog extends StatelessWidget {
  const RecordsLog({
    super.key,
    required this.entries,
    required this.query,
    required this.onQuery,
    required this.onDelete,
    required this.onClear,
  });

  final List<CollectionEntry> entries;
  final String query;
  final ValueChanged<String> onQuery;
  final ValueChanged<CollectionEntry> onDelete;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final rows = filterRecords(entries, query);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: PortalColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PortalColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              const SizedBox(
                width: 280,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recorded Registrations Log',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Comprehensive customer log history',
                      style: TextStyle(color: PortalColors.faint, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 190,
                    child: TextField(
                      onChanged: onQuery,
                      style: const TextStyle(color: PortalColors.text, fontSize: 13),
                      decoration: const InputDecoration(
                        isDense: true,
                        hintText: 'Search entries...',
                        hintStyle: TextStyle(color: PortalColors.faint, fontSize: 12),
                        prefixIcon: Icon(Icons.search, size: 16, color: PortalColors.faint),
                        filled: true,
                        fillColor: PortalColors.bg,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                          borderSide: BorderSide(color: PortalColors.line),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                          borderSide: BorderSide(color: PortalColors.gold),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: onClear,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: PortalColors.rose,
                      side: const BorderSide(color: Color(0x66FB7185)),
                      backgroundColor: const Color(0x1AF43F5E),
                    ),
                    child: const Text('Clear All Data'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: PortalColors.line),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, color: PortalColors.faint, size: 32),
                  SizedBox(height: 8),
                  Text(
                    'No entries recorded yet. Use the entry form above to log data.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: PortalColors.faint, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 860),
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(1.4),
                    1: FlexColumnWidth(1.3),
                    2: FlexColumnWidth(1.1),
                    3: FlexColumnWidth(1.4),
                    4: FlexColumnWidth(1.1),
                    5: FlexColumnWidth(1.8),
                    6: FixedColumnWidth(56),
                  },
                  children: [
                    const TableRow(
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: PortalColors.line)),
                      ),
                      children: [
                        _Head('Timestamp'),
                        _Head('Reference / Phone'),
                        _Head('Bank Category'),
                        _Head('Status / Source'),
                        _Head('Product Type'),
                        _Head('Acquisition Channel'),
                        _Head(''),
                      ],
                    ),
                    for (final entry in rows)
                      TableRow(
                        children: [
                          _Cell(displayWhen(entry), muted: true),
                          _Cell(entry.phone, strong: true),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _Badge(
                                entry.bankType,
                                hnb: entry.bankType == BankTypes.hnb,
                              ),
                            ),
                          ),
                          _Cell(entry.memberStatus),
                          _Cell(entry.productType),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _ChannelBadge(entry.channelType),
                                const SizedBox(height: 4),
                                Text(
                                  entry.channelDetail,
                                  style: const TextStyle(
                                    color: PortalColors.faint,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Delete record',
                            onPressed: () => onDelete(entry),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: PortalColors.faint,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Head extends StatelessWidget {
  const _Head(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: PortalColors.faint,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.text, {this.muted = false, this.strong = false});

  final String text;
  final bool muted;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Text(
        text,
        style: TextStyle(
          color: strong
              ? Colors.white
              : muted
              ? PortalColors.faint
              : PortalColors.muted,
          fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, {required this.hnb});

  final String text;
  final bool hnb;

  @override
  Widget build(BuildContext context) {
    final color = hnb ? PortalColors.blueStat : PortalColors.purple;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ChannelBadge extends StatelessWidget {
  const _ChannelBadge(this.channel);

  final String channel;

  @override
  Widget build(BuildContext context) {
    final color = switch (channel) {
      ChannelTypes.department => PortalColors.emerald,
      ChannelTypes.ownVisit => PortalColors.pink,
      _ => PortalColors.amber,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        channel,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}
