import 'package:flutter_tflite_flutter/pages/camera/camera_page.dart';
import 'package:get/get.dart';
import '../../pages/home/home_page.dart';
import '../bindings/home_binding.dart';

part 'app_routes.dart';

class AppPages {
  static final routes = [
    GetPage(
      binding: HomeBinding(),
      name: Routes.HOME,
      page: () => const HomePage(),
    ),
    GetPage(
      binding: HomeBinding(),
      name: Routes.CAMERA,
      page: () => const CameraPage(),
    ),
  ];
}
