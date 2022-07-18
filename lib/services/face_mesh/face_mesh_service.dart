import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as image_lib;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

import '../../constants/model_file.dart';
import '../../utils/image_utils.dart';
import '../ai_model.dart';

// ignore: must_be_immutable
class FaceMesh extends AiModel {
  FaceMesh({this.interpreter}) {
    loadModel();
  }

  final int inputSize = 192;

  @override
  Interpreter? interpreter;

  @override
  List<Object> get props => [];

  @override
  int get getAddress => interpreter!.address;

  @override
  Future<void> loadModel() async {
    try {
      final interpreterOptions = InterpreterOptions();

      interpreter ??= await Interpreter.fromAsset(ModelFile.faceMesh,
          options: interpreterOptions);

      final outputTensors = interpreter!.getOutputTensors();

      // print('호: ${outputTensors[1].numDimensions()}');
      // print('호: ${outputTensors[1].numElements()}');

      // for (int i = 0; i < 7; i++) {
      //   print('${outputTensors[i].name} - $i: ${outputTensors[i].data.length}');
      // }
      // for (int i = 0; i < 2; i++) {
      //   print(
      //       '${outputTensors[i + 4].name} - $i: ${outputTensors[i + 4].data}');
      // }
      // print('ㅇㅇ: ${outputTensors[6].data}');

      outputTensors.forEach((tensor) {
        outputShapes.add(tensor.shape);
        outputTypes.add(tensor.type);
        outputDatas.add(tensor.data);
      });
    } catch (e) {
      print('Error while creating interpreter: $e');
    }
  }

  @override
  TensorImage getProcessedImage(TensorImage inputImage) {
    final imageProcessor = ImageProcessorBuilder()
        .add(ResizeOp(inputSize, inputSize, ResizeMethod.BILINEAR))
        .add(NormalizeOp(0, 255))
        .build();

    inputImage = imageProcessor.process(inputImage);
    return inputImage;
  }

  @override
  Map<String, dynamic>? predict(image_lib.Image image) {
    if (interpreter == null) {
      print('Interpreter not initialized');
      return null;
    }

    if (Platform.isAndroid) {
      image = image_lib.copyRotate(image, -90);
      image = image_lib.flipHorizontal(image);
    }
    final tensorImage = TensorImage(TfLiteType.float32);
    tensorImage.loadImage(image);
    final inputImage = getProcessedImage(tensorImage);

    TensorBuffer output0 = TensorBufferFloat(outputShapes[0]);
    TensorBuffer output1 = TensorBufferFloat(outputShapes[1]);
    TensorBuffer output2 = TensorBufferFloat(outputShapes[2]);
    TensorBuffer output3 = TensorBufferFloat(outputShapes[3]);
    TensorBuffer output4 = TensorBufferFloat(outputShapes[4]);
    TensorBuffer output5 = TensorBufferFloat(outputShapes[5]);
    TensorBuffer output6 = TensorBufferFloat(outputShapes[6]);

    final inputs = <Object>[inputImage.buffer];

    final outputs = <int, Object>{
      0: output0.buffer,
      1: output1.buffer,
      2: output2.buffer,
      3: output3.buffer,
      4: output4.buffer,
      5: output5.buffer,
      6: output6.buffer,
    };

    // print('ss: ${outputs[6].toString()}');
    // print('ss: ${outputs.length}');

    interpreter!.runForMultipleInputs(inputs, outputs);

    if (output1.getDoubleValue(0) < 0) {
      return null;
    }

    //
    // outputDatas[6] : 7개 중에 7번째 face flag 에 해당하는 데이터 [0,0,0,0]
    // outputDatas[6][3] : 위 데이터의 마지막 값. 현재 face probability threshold 로 추정
    // print('Threshold: ${outputDatas[6][3]}');
    if (outputDatas[6][3] < 65 || outputDatas[6][3] > 67) {
      return null;
    }

    //
    // output을 좌표 값으로 변환하는 과정
    // 링크 참고: https://drive.google.com/file/d/1tV7EJb3XgMS7FwOErTgLU1ZocYyNmwlf/preview
    // final allLandmarkPoints = output0.getDoubleList().reshape([468, 3]);
    final lipsLandmarkPoints = output1.getDoubleList().reshape([80, 2]);
    final leftEyeLandmarkPoints = output2.getDoubleList().reshape([71, 2]);
    final rightEyeLandmarkPoints = output3.getDoubleList().reshape([71, 2]);
    // final leftIrisLandmarkPoints = output4.getDoubleList().reshape([5, 2]);
    // final rightIrisLandmarkPoints = output5.getDoubleList().reshape([5, 2]);

    final landmarkResults = <Offset>[];

    // for (var point in allLandmarkPoints) {
    //   landmarkResults.add(Offset(
    //     point[0] / inputSize * image.width,
    //     point[1] / inputSize * image.height,
    //   ));
    // }
    for (var point in lipsLandmarkPoints) {
      landmarkResults.add(Offset(
        point[0] / inputSize * image.width,
        point[1] / inputSize * image.height,
      ));
    }
    for (var point in leftEyeLandmarkPoints) {
      landmarkResults.add(Offset(
        point[0] / inputSize * image.width,
        point[1] / inputSize * image.height,
      ));
    }
    for (var point in rightEyeLandmarkPoints) {
      landmarkResults.add(Offset(
        point[0] / inputSize * image.width,
        point[1] / inputSize * image.height,
      ));
    }
    // for (var point in leftIrisLandmarkPoints) {
    //   landmarkResults.add(Offset(
    //     point[0] / inputSize * image.width,
    //     point[1] / inputSize * image.height,
    //   ));
    // }
    // for (var point in rightIrisLandmarkPoints) {
    //   landmarkResults.add(Offset(
    //     point[0] / inputSize * image.width,
    //     point[1] / inputSize * image.height,
    //   ));
    // }

    // print(
    //     'inputSize: ${inputSize}, height: ${image.height}, width: ${image.width}');

    return {'point': landmarkResults};
  }
}

Map<String, dynamic>? runFaceMesh(Map<String, dynamic> params) {
  final faceMesh =
      FaceMesh(interpreter: Interpreter.fromAddress(params['detectorAddress']));
  final image = ImageUtils.convertCameraImage(params['cameraImage']);
  final result = faceMesh.predict(image!);

  return result;
}
