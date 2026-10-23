import 'package:flutter/material.dart';

import '../logic/collection_logic.dart';
import '../models/catalog.dart';
import '../models/collection_entry.dart';
import '../theme/app_theme.dart';
import 'app_button.dart';

class EntriesPanel extends StatelessWidget {
  const EntriesPanel({
    super.key,
    required this.entries,
    required this.onDelete,
  });

  final List<CollectionEntry> entries;
  final ValueChanged<CollectionEntry> onDelete;

  @override
  Widget build(BuildContext context) {
    final rows = newestFirst(entries);
    return Container(
      decoration: panelDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PanelHead(
            title: 'Collection entries',
            subtitle:
                'Each number stays with the branch or company where it was collected.',
            trailing: _AutoSaved(),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final tableWidth = constraints.maxWidth < 640
                  ? 640.0
                  : constraints.maxWidth;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _TableHeader(),
                      if (rows.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 36,
                          ),
                          child: Column(
                            children: [
                              Text(
                                'No entries yet',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Add a phone number to start tracking your collections.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        for (final entry in rows)
                          _EntryRow(
                            entry: entry,
                            onDelete: () => onDelete(entry),
                          ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PanelHead extends StatelessWidget {
  const _PanelHead({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 19, 20, 19),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ],
      ),
    );
  }
}

class _AutoSaved extends StatelessWidget {
  const _AutoSaved();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.statusDot,
            shape: BoxShape.circle,
          ),
          child: SizedBox(width: 7, height: 7),
        ),
        SizedBox(width: 6),
        Text(
          'Auto-saved',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.green,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.headerTh,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            _HeaderCell('Phone number', flex: 16),
            _HeaderCell('Bank', flex: 12),
            _HeaderCell('Category', flex: 16),
            _HeaderCell('Date & time', flex: 14),
            SizedBox(width: 92),
          ],
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label, {required this.flex});

  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.headerThFg,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry, required this.onDelete});

  final CollectionEntry entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final hnb = entry.bank == 'HNB';
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            Expanded(
              flex: 16,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                child: Text(
                  entry.phone,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 12,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: hnb ? AppColors.tagHnbBg : AppColors.tagBg,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        entry.bank,
                        style: TextStyle(
                          color: hnb ? AppColors.tagHnbFg : AppColors.tagFg,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (entry.place.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        entry.place,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 16,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                child: Text(
                  SoloCategory.labelFor(entry.category),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
            Expanded(
              flex: 14,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                child: Text(
                  displayWhen(entry),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
            SizedBox(
              width: 92,
              child: Align(
                alignment: Alignment.centerLeft,
                child: AppButton(
                  label: 'Delete',
                  kind: AppButtonKind.outline,
                  compact: true,
                  onPressed: onDelete,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
