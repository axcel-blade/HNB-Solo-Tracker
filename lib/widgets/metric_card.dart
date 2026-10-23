import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.foot,
    required this.value,
    required this.compact,
    required this.horizontal,
  });

  final String label;
  final String foot;
  final int value;
  final bool compact;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final labelBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          foot,
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
      ],
    );
    final number = Text(
      '$value',
      style: TextStyle(
        fontSize: compact ? 26 : 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
        height: 1,
        color: AppColors.ink,
      ),
    );
    return Container(
      padding: EdgeInsets.all(compact ? 13 : 18),
      decoration: panelDecoration(),
      child: horizontal
          ? Row(
              children: [
                Expanded(child: labelBlock),
                number,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                labelBlock,
                const SizedBox(height: 8),
                number,
              ],
            ),
    );
  }
}
