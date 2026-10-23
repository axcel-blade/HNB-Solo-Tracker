import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class BankRatioChart extends StatelessWidget {
  const BankRatioChart({super.key, required this.hnb, required this.other});

  final int hnb;
  final int other;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 168,
          child: CustomPaint(
            painter: _DoughnutPainter(hnb: hnb, other: other),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(color: Color(0xFF3B82F6), label: 'HNB Bank'),
            SizedBox(width: 16),
            _LegendDot(color: Color(0xFFA855F7), label: 'Other Bank'),
          ],
        ),
      ],
    );
  }
}

class ChannelBarChart extends StatelessWidget {
  const ChannelBarChart({
    super.key,
    required this.branches,
    required this.departments,
    required this.ownVisits,
  });

  final int branches;
  final int departments;
  final int ownVisits;

  @override
  Widget build(BuildContext context) {
    final peak = math.max(1, math.max(branches, math.max(departments, ownVisits)));
    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _Bar(
            label: 'Branch',
            value: branches,
            peak: peak,
            color: const Color(0xFFF59E0B),
          ),
          _Bar(
            label: 'Department',
            value: departments,
            peak: peak,
            color: const Color(0xFF10B981),
          ),
          _Bar(
            label: 'Own Visit',
            value: ownVisits,
            peak: peak,
            color: const Color(0xFFEC4899),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.label,
    required this.value,
    required this.peak,
    required this.color,
  });

  final String label;
  final int value;
  final int peak;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            Text(
              '$value',
              style: const TextStyle(color: PortalColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: value == 0 ? 0.04 : value / peak,
                  widthFactor: 0.62,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: PortalColors.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: PortalColors.muted, fontSize: 11),
        ),
      ],
    );
  }
}

class _DoughnutPainter extends CustomPainter {
  _DoughnutPainter({required this.hnb, required this.other});

  final int hnb;
  final int other;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 28
      ..strokeCap = StrokeCap.butt;
    final total = hnb + other;
    if (total == 0) {
      stroke.color = PortalColors.line;
      canvas.drawArc(rect, 0, math.pi * 2, false, stroke);
      return;
    }
    final hnbSweep = (hnb / total) * math.pi * 2;
    stroke.color = const Color(0xFF3B82F6);
    canvas.drawArc(rect, -math.pi / 2, hnbSweep, false, stroke);
    stroke.color = const Color(0xFFA855F7);
    canvas.drawArc(rect, -math.pi / 2 + hnbSweep, math.pi * 2 - hnbSweep, false, stroke);
  }

  @override
  bool shouldRepaint(covariant _DoughnutPainter oldDelegate) {
    return oldDelegate.hnb != hnb || oldDelegate.other != other;
  }
}
