import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_tflite_flutter/controllers/face_mesh_controller.dart';

class FaceMeshPainter extends CustomPainter {
  final List<Offset> points;
  final double ratio;
  final FaceMeshController faceMeshController;

  FaceMeshPainter({
    required this.points,
    required this.ratio,
    required this.faceMeshController,
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

      var redPoints = points.sublist(0, 1);
      var yellowPoints = points;
      var bluePoints = [points[5], points[15]];
      var greenPoints = [points[134], points[205]];

      // print('최대: ${greenPoints[1]}');
      // print('최소: ${greenPoints[0]}');
      var eyeSize = (greenPoints[1] - greenPoints[0]).distance;
      var lipSize = (bluePoints[1] - bluePoints[0]).distance;
      // print('길이: $eyeSize || 입술: $lipSize || 비율: ${lipSize / eyeSize}');

      // controller에 지속적으로 업데이트 하는 함수
      faceMeshController.updateResult(eyeSize, lipSize, lipSize / eyeSize);

      canvas.drawPoints(PointMode.points,
          yellowPoints.map((point) => point * ratio).toList(), paint1);

      canvas.drawPoints(PointMode.points,
          redPoints.map((point) => point * ratio).toList(), paint2);

      // 입 위 to 아래
      canvas.drawPoints(PointMode.points,
          bluePoints.map((point) => point * ratio).toList(), paint3);

      canvas.drawLine(bluePoints[0] * ratio, bluePoints[1] * ratio, paint3);

      // 머리 위 to 아래
      canvas.drawPoints(PointMode.points,
          greenPoints.map((point) => point * ratio).toList(), paint4);

      canvas.drawLine(greenPoints[0] * ratio, greenPoints[1] * ratio, paint4);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
