import 'package:flutter/material.dart';

import '../models/catalog.dart';
import '../theme/app_theme.dart';
import 'app_button.dart';

typedef OptionSelection = ({String bank, String category});

Future<OptionSelection?> showOptionsDialog(BuildContext context, String phone) {
  return showDialog<OptionSelection>(
    context: context,
    barrierColor: AppColors.backdrop,
    builder: (context) => OptionsDialog(phone: phone),
  );
}

class OptionsDialog extends StatefulWidget {
  const OptionsDialog({super.key, required this.phone});

  final String phone;

  @override
  State<OptionsDialog> createState() => _OptionsDialogState();
}

class _OptionsDialogState extends State<OptionsDialog> {
  int _step = 1;
  String? _bank;
  String? _category;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width > 480;
    final stepOne = _step == 1;
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      insetPadding: const EdgeInsets.all(18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.sizeOf(context).height - 36,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stepOne ? 'STEP 1 OF 2' : 'STEP 2 OF 2',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.blue,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.9,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                stepOne ? 'Select the bank' : 'Select the Solo category',
                style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 7),
              Text(
                stepOne
                    ? 'Choose the bank for ${widget.phone}.'
                    : 'Choose which column this entry should be counted in.',
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 20),
              _ChoiceGrid(
                columns: wide ? 2 : 1,
                children: stepOne
                    ? [
                        for (final bank in BankOption.all)
                          _ChoiceTile(
                            title: bank.name,
                            subtitle: bank.description,
                            selected: _bank == bank.name,
                            onTap: () => setState(() => _bank = bank.name),
                          ),
                      ]
                    : [
                        for (final category in SoloCategory.all)
                          _ChoiceTile(
                            title: category.name,
                            subtitle: 'Count this entry in this category.',
                            selected: _category == category.id,
                            onTap: () => setState(() => _category = category.id),
                          ),
                      ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  AppButton(
                    label: stepOne ? 'Cancel' : '← Back',
                    kind: AppButtonKind.outline,
                    onPressed: () {
                      if (stepOne) {
                        Navigator.of(context).pop();
                      } else {
                        setState(() => _step = 1);
                      }
                    },
                  ),
                  const Spacer(),
                  AppButton(
                    label: stepOne ? 'Next →' : 'Save entry ✓',
                    onPressed: _canContinue
                        ? () {
                            if (stepOne) {
                              setState(() => _step = 2);
                              return;
                            }
                            Navigator.of(context).pop((
                              bank: _bank!,
                              category: _category!,
                            ));
                          }
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _canContinue => _step == 1 ? _bank != null : _category != null;
}

class _ChoiceGrid extends StatelessWidget {
  const _ChoiceGrid({required this.columns, required this.children});

  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var index = 0; index < children.length; index += columns) {
      final end = index + columns > children.length
          ? children.length
          : index + columns;
      final slice = children.sublist(index, end);
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var slot = 0; slot < columns; slot++) ...[
              if (slot > 0) const SizedBox(width: 12),
              Expanded(
                child: slot < slice.length ? slice[slot] : const SizedBox(),
              ),
            ],
          ],
        ),
      );
      if (end < children.length) rows.add(const SizedBox(height: 12));
    }
    return Column(children: rows);
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.choiceSelected : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
        side: BorderSide(
          color: selected ? AppColors.blue : AppColors.line,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        hoverColor: AppColors.choiceHover,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 18, 12, 18),
          decoration: selected
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: const [
                    BoxShadow(color: Color(0x202463EB), spreadRadius: 2),
                  ],
                )
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
