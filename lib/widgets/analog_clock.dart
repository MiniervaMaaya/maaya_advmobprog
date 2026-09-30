import 'package:flutter/material.dart';
import 'dart:math';

/// Analog clock widget
class AnalogClock extends StatefulWidget {
  final double size;

  const AnalogClock({super.key, this.size = 120});

  @override
  State<AnalogClock> createState() => _AnalogClockState();
}

class _AnalogClockState extends State<AnalogClock>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 60),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: ClockPainter(
          animation: _controller,
        ),
      ),
    );
  }
}

/// Custom painter for the analog clock
class ClockPainter extends CustomPainter {
  final Animation<double> animation;

  ClockPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00BCD4)
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw circle
    canvas.drawCircle(center, radius, paint);

    // Draw clock numbers (simplified)
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Get current time
    final now = DateTime.now();
    final seconds = now.second.toDouble() + now.millisecond / 1000;
    final minutes = now.minute.toDouble() + seconds / 60;
    final hours = (now.hour % 12).toDouble() + minutes / 60;

    // Draw hour hand
    final hourAngle = (hours * 30 - 90) * pi / 180;
    final hourLength = radius * 0.5;
    canvas.drawLine(
      center,
      Offset(
        center.dx + hourLength * cos(hourAngle),
        center.dy + hourLength * sin(hourAngle),
      ),
      paint..strokeWidth = 4,
    );

    // Draw minute hand
    final minuteAngle = (minutes * 6 - 90) * pi / 180;
    final minuteLength = radius * 0.7;
    canvas.drawLine(
      center,
      Offset(
        center.dx + minuteLength * cos(minuteAngle),
        center.dy + minuteLength * sin(minuteAngle),
      ),
      paint..strokeWidth = 2,
    );

    // Draw center dot
    canvas.drawCircle(center, 4, paint);
  }

  @override
  bool shouldRepaint(ClockPainter oldDelegate) => true;
}
