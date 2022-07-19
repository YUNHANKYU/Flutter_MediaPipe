import 'dart:isolate';

import 'package:camera/camera.dart';

import '../utils/isolate_utils.dart';
import 'ai_model.dart';
// import 'face_detection/face_detection_service.dart';
import 'face_mesh/face_mesh_service.dart';
// import 'hands/hands_service.dart';
// import 'pose/pose_service.dart';
import 'service_locator.dart';

enum Models {
  FaceDetection,
  FaceMesh,
  Hands,
  Pose,
}

class ModelInferenceService {
  late FaceMesh faceMesh;
  late Function handler;
  Map<String, dynamic>? inferenceResults;

  Future<Map<String, dynamic>?> inference({
    required IsolateUtils isolateUtils,
    required CameraImage cameraImage,
  }) async {
    final responsePort = ReceivePort();

    isolateUtils.sendMessage(
      handler: handler,
      params: {
        'cameraImage': cameraImage,
        'detectorAddress': faceMesh.getAddress,
      },
      sendPort: isolateUtils.sendPort,
      responsePort: responsePort,
    );

    inferenceResults = await responsePort.first;
    responsePort.close();
  }

  void setModelConfig() {
    faceMesh = locator<FaceMesh>();
    handler = runFaceMesh;
  }
}
