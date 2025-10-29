// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RiskGauge extends StatelessWidget {
  final double percentage;
  const RiskGauge({super.key, required this.percentage});

  @override
  Widget build(BuildContext context) {
    final risk = percentage.clamp(0, 100);
    final color = AppTheme.statusColor(risk.toInt());
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: risk / 100),
      duration: const Duration(milliseconds: 400),
      builder: (context, value, _) {
        return CustomPaint(
          painter: _GaugePainter(value, color),
          child: Center(
            child: Text(
              '${(value * 100).round()}%',
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value; // 0..1
  final Color color;
  _GaugePainter(this.value, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.shortestSide * 0.08;
    final rect = Offset.zero & size;
    const start = 3.14; // pi
    const sweep = 3.14; // 180°
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeCap = StrokeCap.round;
    final fgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = color
      ..strokeCap = StrokeCap.round;

    final pad = stroke;
    final arcRect = Rect.fromLTWH(
      pad,
      pad,
      rect.width - 2 * pad,
      rect.height - 2 * pad,
    );

    canvas.drawArc(arcRect, start, sweep, false, bgPaint);
    canvas.drawArc(arcRect, start, sweep * value, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.color != color;
}
