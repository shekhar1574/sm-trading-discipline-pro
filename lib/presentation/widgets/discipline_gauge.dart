import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/theme/app_theme.dart';

/// Circular gauge showing the 0-100 discipline score with a color that
/// shifts from red -> gold -> green as discipline improves.
class DisciplineGauge extends StatelessWidget {
  final int score;
  final double size;

  const DisciplineGauge({super.key, required this.score, this.size = 140});

  Color get _scoreColor {
    if (score >= 75) return AppColors.profit;
    if (score >= 45) return AppColors.warning;
    return AppColors.loss;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _GaugePainter(score: score, color: _scoreColor),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  fontSize: size * 0.26,
                  fontWeight: FontWeight.w800,
                  color: _scoreColor,
                ),
              ),
              const Text(
                'DISCIPLINE',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.2,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final int score;
  final Color color;

  _GaugePainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    final backgroundPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final foregroundPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi * 1.25;
    const sweepAngleMax = math.pi * 1.5;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        startAngle, sweepAngleMax, false, backgroundPaint);

    final sweep = sweepAngleMax * (score.clamp(0, 100) / 100);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        startAngle, sweep, false, foregroundPaint);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.score != score || oldDelegate.color != color;
}
