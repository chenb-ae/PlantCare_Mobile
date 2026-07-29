import 'package:flutter/material.dart';

class GoogleLogoIcon extends StatelessWidget {
  final double size;
  const GoogleLogoIcon({super.key, this.size = 24.0});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);
    final double strokeWidth = size.width * 0.22;

    final Paint bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final Paint greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final Paint yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final Paint redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final Rect rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    // Draw Red arc (top)
    canvas.drawArc(rect, -0.4, -1.8, false, redPaint);
    // Draw Yellow arc (left)
    canvas.drawArc(rect, -2.2, -1.1, false, yellowPaint);
    // Draw Green arc (bottom)
    canvas.drawArc(rect, -3.3, -1.2, false, greenPaint);
    // Draw Blue arc (right)
    canvas.drawArc(rect, 0.4, 1.2, false, bluePaint);

    // Draw Blue horizontal bar
    final Paint fillBlue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    final Rect barRect = Rect.fromLTWH(
      center.dx - radius * 0.1,
      center.dy - strokeWidth / 2,
      radius * 1.05,
      strokeWidth,
    );
    canvas.drawRect(barRect, fillBlue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
