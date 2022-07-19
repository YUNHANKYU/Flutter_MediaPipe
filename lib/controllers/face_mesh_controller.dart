import 'package:get/get.dart';

class FaceMeshController extends GetxController {
  double eyeSize = 0.0;
  double lipSize = 0.0;
  double ratio = 0.0;

  updateResult(double eyeSizeP, double lipSizeP, double ratioP) {
    eyeSize = eyeSizeP;
    lipSize = lipSizeP;
    ratio = ratioP;
  }
}
