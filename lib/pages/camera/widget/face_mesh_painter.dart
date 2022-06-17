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
        ..strokeWidth = 10;

      var redPoints = points.sublist(10, 20);
      var yellowPoints = points;
      var bluePoints = [points[5], points[15]];

      print('최대: ${bluePoints[1]}');
      print('최소: ${bluePoints[0]}');

      print('길이: ${(bluePoints[1] - bluePoints[0]).distance}');

      canvas.drawPoints(PointMode.points,
          yellowPoints.map((point) => point * ratio).toList(), paint1);

      canvas.drawPoints(PointMode.points,
          redPoints.map((point) => point * ratio).toList(), paint2);

      canvas.drawPoints(PointMode.points,
          bluePoints.map((point) => point * ratio).toList(), paint3);

      canvas.drawLine(bluePoints[0] * ratio, bluePoints[1] * ratio, paint3);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
