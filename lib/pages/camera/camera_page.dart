import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tflite_flutter/controllers/face_mesh_controller.dart';
import 'package:get/get.dart';

import '../../services/model_inference_service.dart';
import '../../services/service_locator.dart';
import '../../utils/isolate_utils.dart';
import 'widget/model_camera_preview.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({
    this.index = 1,
    Key? key,
  }) : super(key: key);

  final int index;

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  CameraController? _cameraController;
  late List<CameraDescription> _cameras;
  late CameraDescription _cameraDescription;

  bool _isRun = false;
  bool _predicting = false;
  bool _draw = false;

  late IsolateUtils _isolateUtils;
  late ModelInferenceService _modelInferenceService;

  final _faceMeshController = Get.find<FaceMeshController>();

  @override
  void initState() {
    _modelInferenceService = locator<ModelInferenceService>();
    _initStateAsync();
    super.initState();
  }

  void _initStateAsync() async {
    _isolateUtils = IsolateUtils();
    await _isolateUtils.initIsolate();
    await _initCamera();
    _predicting = false;
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _cameraController = null;
    _isolateUtils.dispose();
    _modelInferenceService.inferenceResults = null;
    super.dispose();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    _cameraDescription = _cameras[1];
    _isRun = false;
    _onNewCameraSelected(_cameraDescription);
  }

  void _onNewCameraSelected(CameraDescription cameraDescription) async {
    _cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    _cameraController!.addListener(() {
      if (mounted) setState(() {});
      if (_cameraController!.value.hasError) {
        _showInSnackBar(
            'Camera error ${_cameraController!.value.errorDescription}');
      }
    });

    try {
      await _cameraController!.initialize().then((value) {
        if (!mounted) return;
        _imageStreamToggle();
      });
    } on CameraException catch (e) {
      _showInSnackBar('Error: ${e.code}\n${e.description}');
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _showInSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // _imageStreamToggle;
        if (_draw) {
          setState(() {
            _draw = false;
          });
        }
        if (_isRun) {
          _isRun = false;
          _cameraController!.stopImageStream();
        }
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        backgroundColor:
            _isRun && _modelInferenceService.inferenceResults != null
                ? Colors.green
                : Colors.black,
        appBar: _buildAppBar,
        body: ModelCameraPreview(
          cameraController: _cameraController,
          index: widget.index,
          draw: _draw,
        ),
        floatingActionButton: _buildFloatingActionButton,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  AppBar get _buildAppBar => AppBar(
        title: Text(
          // models[widget.index]['title']!,
          "개구량 촬영하기",
          style: TextStyle(
              color: Colors.white,
              fontSize: ScreenUtil().setSp(28),
              fontWeight: FontWeight.bold),
        ),
      );

  Widget get _buildFloatingActionButton => InkWell(
        onTap: _imageStreamToggle,
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * 0.08,
          color: Colors.blue,
          child: Align(
            alignment: Alignment.center,
            child: Text(
              '촬영하기',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.0,
                  fontWeight: FontWeight.w400),
            ),
          ),
        ),
      );

  void _imageStreamToggle() {
    setState(() {
      _draw = !_draw;
    });

    _isRun = !_isRun;
    if (_isRun) {
      _cameraController!.startImageStream(
        (CameraImage cameraImage) async =>
            await _inference(cameraImage: cameraImage),
      );
      _cameraController!.resumePreview();
    } else {
      _cameraController!.stopImageStream();
      _cameraController!.pausePreview();

      // TODO: 촬영하기 버튼 클릭 시 최종 길이 정보 확인하기
      print(
          '길이: ${_faceMeshController.eyeSize} || 입술: ${_faceMeshController.lipSize} || 비율: ${_faceMeshController.ratio}');
    }
  }

  void get _cameraDirectionToggle {
    setState(() {
      _draw = false;
    });
    _isRun = false;
    if (_cameraController!.description.lensDirection ==
        _cameras.first.lensDirection) {
      _onNewCameraSelected(_cameras.last);
    } else {
      _onNewCameraSelected(_cameras.first);
    }
  }

  Future<void> _inference({required CameraImage cameraImage}) async {
    if (!mounted) return;

    if (_modelInferenceService.model.interpreter != null) {
      if (_predicting || !_draw) {
        return;
      }

      setState(() {
        _predicting = true;
      });

      if (_draw) {
        await _modelInferenceService.inference(
          isolateUtils: _isolateUtils,
          cameraImage: cameraImage,
        );
      }

      setState(() {
        _predicting = false;
      });
    }
  }
}
