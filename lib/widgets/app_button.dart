import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum AppButtonKind { primary, outline, danger }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = AppButtonKind.primary,
    this.expand = false,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonKind kind;
  final bool expand;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final colors = _colors(enabled);
    final button = Material(
      color: colors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colors.border),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 9 : 15,
            vertical: compact ? 6 : 11,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.foreground,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 13 : 14,
            ),
          ),
        ),
      ),
    );
    if (!expand) return button;
    return SizedBox(width: double.infinity, child: button);
  }

  _ButtonColors _colors(bool enabled) {
    switch (kind) {
      case AppButtonKind.primary:
        return _ButtonColors(
          background: enabled ? AppColors.blue : AppColors.blue.withValues(alpha: 0.4),
          foreground: Colors.white,
          border: enabled ? AppColors.blue : AppColors.blue.withValues(alpha: 0.0),
        );
      case AppButtonKind.outline:
        return const _ButtonColors(
          background: Colors.white,
          foreground: AppColors.ink,
          border: AppColors.line,
        );
      case AppButtonKind.danger:
        return const _ButtonColors(
          background: AppColors.dangerBg,
          foreground: AppColors.dangerFg,
          border: AppColors.dangerBorder,
        );
    }
  }
}

class _ButtonColors {
  const _ButtonColors({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;
}
