import 'package:flutter_tflite_flutter/controllers/face_mesh_controller.dart';
import 'package:get/get.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<FaceMeshController>(FaceMeshController());
  }
}
