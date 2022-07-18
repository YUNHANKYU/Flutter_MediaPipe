import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tflite_flutter/app/routes/app_pages.dart';
import 'package:get/get.dart';

import '../../services/model_inference_service.dart';
import '../../services/service_locator.dart';
import '../camera/camera_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            'Face Mesh',
            style: TextStyle(
                color: Colors.black,
                fontSize: ScreenUtil().setSp(28),
                fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: ElevatedButton(
            child: const Text('개구량 측정하기'),
            onPressed: () => _onTapCamera(context),
          ),
        ));
  }

  void _onTapCamera(BuildContext context) {
    //TODO: index 넣던 부분 제거하기
    locator<ModelInferenceService>().setModelConfig(1);
    Get.toNamed(Routes.CAMERA);
  }
}
