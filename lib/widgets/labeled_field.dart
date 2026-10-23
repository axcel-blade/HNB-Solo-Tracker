import 'package:flutter/material.dart';

import '../logic/collection_logic.dart';
import '../theme/app_theme.dart';

InputDecoration appInputDecoration({String? hint, Widget? suffix}) {
  const border = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(10)),
    borderSide: BorderSide(color: AppColors.inputBorder),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      color: AppColors.muted,
      fontWeight: FontWeight.w400,
      fontSize: 15,
    ),
    filled: true,
    fillColor: Colors.white,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
    suffixIcon: suffix,
    suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    enabledBorder: border,
    disabledBorder: border,
    border: border,
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: AppColors.blue, width: 1.4),
    ),
  );
}

class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.child,
    this.hint,
  });

  final String label;
  final Widget child;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 7),
          child,
          if (hint != null) ...[
            const SizedBox(height: 7),
            Text(
              hint!,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onPick,
    this.hint,
    this.placeholder = 'Select a date',
    this.onClear,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onPick;
  final VoidCallback? onClear;
  final String? hint;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return LabeledField(
      label: label,
      hint: hint,
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: onPick,
          borderRadius: BorderRadius.circular(10),
          child: InputDecorator(
            decoration: appInputDecoration(
              suffix: hasValue && onClear != null
                  ? IconButton(
                      tooltip: 'Clear date',
                      onPressed: onClear,
                      icon: const Icon(Icons.close, size: 18, color: AppColors.muted),
                    )
                  : const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.muted),
            ),
            child: Text(
              hasValue ? formatEntryDate(isoDate(value!)) : placeholder,
              style: TextStyle(
                fontSize: 15,
                color: hasValue ? AppColors.ink : AppColors.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
