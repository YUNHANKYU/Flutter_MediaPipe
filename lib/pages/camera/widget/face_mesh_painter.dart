import 'dart:ui';

import 'package:flutter/material.dart';

class FaceMeshPainter extends CustomPainter {
  final List<Offset> points;
  final double ratio;

  FaceMeshPainter({
    required this.points,
    required this.ratio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isNotEmpty) {
      var paint1 = Paint()
        ..color = Colors.amber
        ..strokeWidth = 4;
      var paint2 = Paint()
        ..color = Colors.red
        ..strokeWidth = 4;
      var paint3 = Paint()
        ..color = Colors.blue
        ..strokeWidth = 6;
      var paint4 = Paint()
        ..color = Colors.green
        ..strokeWidth = 4;

      var yellowPoints = points;
      var bluePoints = [points[5], points[15]];
      var greenPoints = [points[134], points[205]];

      canvas.drawPoints(PointMode.points,
          yellowPoints.map((point) => point * ratio).toList(), paint1);

      // 입 위 to 아래
      canvas.drawPoints(PointMode.points,
          bluePoints.map((point) => point * ratio).toList(), paint3);

      canvas.drawLine(bluePoints[0] * ratio, bluePoints[1] * ratio, paint3);

      // 머리 Left to Right
      canvas.drawPoints(PointMode.points,
          greenPoints.map((point) => point * ratio).toList(), paint4);

      canvas.drawLine(greenPoints[0] * ratio, greenPoints[1] * ratio, paint4);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
