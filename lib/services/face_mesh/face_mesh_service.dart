import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as image_lib;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

import '../../constants/model_file.dart';
import '../../utils/image_utils.dart';

// ignore: must_be_immutable
class FaceMesh {
  FaceMesh({this.interpreter}) {
    loadModel();
  }

  final outputShapes = <List<int>>[];
  final outputTypes = <TfLiteType>[];
  final outputDatas = <Uint8List>[];

  Interpreter? interpreter;

  final int inputSize = 192;

  List<Object> get props => [];

  int get getAddress => interpreter!.address;

  Future<void> loadModel() async {
    try {
      final interpreterOptions = InterpreterOptions();

      interpreter ??= await Interpreter.fromAsset(ModelFile.faceMesh,
          options: interpreterOptions);

      final outputTensors = interpreter!.getOutputTensors();

      outputTensors.forEach((tensor) {
        outputShapes.add(tensor.shape);
        outputTypes.add(tensor.type);
        outputDatas.add(tensor.data);
      });
    } catch (e) {
      print('Error while creating interpreter: $e');
    }
  }

  TensorImage getProcessedImage(TensorImage inputImage) {
    final imageProcessor = ImageProcessorBuilder()
        .add(ResizeOp(inputSize, inputSize, ResizeMethod.BILINEAR))
        .add(NormalizeOp(0, 255))
        .build();

    inputImage = imageProcessor.process(inputImage);
    return inputImage;
  }

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

    interpreter!.runForMultipleInputs(inputs, outputs);

    if (output1.getDoubleValue(0) < 0) {
      return null;
    }

    if (outputDatas[6][3] < 65 || outputDatas[6][3] > 67) {
      return null;
    }

    final lipsLandmarkPoints = output1.getDoubleList().reshape([80, 2]);
    final leftEyeLandmarkPoints = output2.getDoubleList().reshape([71, 2]);
    final rightEyeLandmarkPoints = output3.getDoubleList().reshape([71, 2]);

    final landmarkResults = <Offset>[];

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

    var bluePoints = [landmarkResults[5], landmarkResults[15]];
    var greenPoints = [landmarkResults[134], landmarkResults[205]];

    // print('최대: ${greenPoints[1]}');
    // print('최소: ${greenPoints[0]}');
    var eyeSize = (greenPoints[1] - greenPoints[0]).distance;
    var lipSize = (bluePoints[1] - bluePoints[0]).distance;

    // print('길이: ${eyeSize} || 입술: ${lipSize} || 비율: ${lipSize / eyeSize}');

    return {
      'point': landmarkResults,
      'eyeSize': eyeSize,
      'lipSize': lipSize,
      'ratio': lipSize / eyeSize
    };
  }
}

Map<String, dynamic>? runFaceMesh(Map<String, dynamic> params) {
  final faceMesh =
      FaceMesh(interpreter: Interpreter.fromAddress(params['detectorAddress']));
  final image = ImageUtils.convertCameraImage(params['cameraImage']);
  final result = faceMesh.predict(image!);

  return result;
}
