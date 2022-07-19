import 'package:flutter_tflite_flutter/pages/camera/camera_page.dart';
import 'package:get/get.dart';
import '../../pages/home/home_page.dart';

part 'app_routes.dart';

class AppPages {
  static final routes = [
    GetPage(
      name: Routes.HOME,
      page: () => const HomePage(),
    ),
    GetPage(
      name: Routes.CAMERA,
      page: () => const CameraPage(),
    ),
  ];
}
