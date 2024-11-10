import 'package:a_eye/providers/firebase.dart';
import 'package:a_eye/utils/image_functions.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math' as math;
import 'dart:io';
import '../utils/app_theme.dart';

const String ssd = "SSD MobileNet";
const String yolo = "Tiny YOLOv2";

typedef void Callback(List<dynamic> list, int h, int w);

// ignore: must_be_immutable
class Camera extends StatefulWidget {
  final List<CameraDescription> cameras;
  final Callback setRecognitions;
  bool model;
  bool blackout;

  double zoom;
  bool isDetecting;
  int rotation;

  Camera(this.cameras, this.setRecognitions, this.model, this.blackout,
      this.zoom, this.isDetecting, this.rotation);

  @override
  _CameraState createState() => new _CameraState();
}

class _CameraState extends State<Camera> {
  CameraController? controller;
  bool isDetecting = false;
  String? subdir;

  bool? permission;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 1), () {
      initialize();
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
    if (subdir != null) {
      Future.delayed(Duration.zero, () async {
        var directory;
        if (Platform.isIOS) {
          directory = await getApplicationDocumentsDirectory();
        } else {
          directory = await getExternalStorageDirectory();
        }

        final myImagePath = '${directory.path}/Shots/$subdir';
        final myVideoPath = '${directory.path}/Shots';
        Firebase_backend.makeMovie(myImagePath, myVideoPath, subdir!);
        subdir = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if ((controller == null || !controller!.value.isInitialized) &&
        permission == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SpinKitFadingCube(
            color: AppTheme.appIndigo,
            duration: Duration(milliseconds: 500),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Initializing Neural Network...',
              style: AppTheme.title2,
            ),
          )
        ],
      );
    } else if (permission == false) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                'Camera permission must be enabled.',
                style: AppTheme.title2,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.notWhite, // background
              foregroundColor: AppTheme.appIndigo, // foreground
            ),
            onPressed: () async {
              Permission.camera.status.then((value) => print(value));
              var answer = await Permission.camera.request();
              if (answer == PermissionStatus.granted) {
                permission = true;
                await initCameras();
              } else if (answer == PermissionStatus.permanentlyDenied) {
                openAppSettings();
              }
            },
            child: Text('Tap to enable'),
          )
        ],
      );
    } else if (permission = true && controller != null) {
      Size? tmp = MediaQuery.of(context).size;
      var screenH = math.max(tmp.height, tmp.width);
      var screenW = math.min(tmp.height, tmp.width);
      tmp = controller!.value.previewSize;
      var previewH = math.max(tmp!.height, tmp.width);
      var previewW = math.min(tmp.height, tmp.width);
      var screenRatio = screenH / screenW;
      var previewRatio = previewH / previewW;
      controller!.setZoomLevel(widget.zoom);

      return OverflowBox(
        maxHeight: screenRatio > previewRatio
            ? screenH
            : screenW / previewW * previewH,
        maxWidth: screenRatio > previewRatio
            ? screenH / previewH * previewW
            : screenW,
        child: widget.blackout
            ? Container(
                color: Colors.black,
              )
            : CameraPreview(
                controller!,
              ),
      );
    } else {
      return Container();
    }
  }

  void initialize() async {
    permission = await Permission.camera.status.isGranted;
    initCameras();
  }

  Future<void> initCameras() async {
    if (widget.cameras == null || widget.cameras.length < 1) {
      print('No camera is found');
    } else if (permission == false) {
      setState(() {});
    } else {
      controller = new CameraController(
          widget.cameras[0], ResolutionPreset.high,
          enableAudio: false);

      await controller!.initialize();
      await controller!.lockCaptureOrientation(DeviceOrientation.portraitUp);
      if (!mounted) {
        return;
      }

      setState(() {});
      Future.delayed(Duration(milliseconds: 250), () {});

      controller!.startImageStream((CameraImage img) async {
        // TODO create method with Timer(const Duration(seconds: 10), () => callback());
        // to only check every few seconds by setting isDetecting to true
        // once an object is detected automatically shut off the sleep function until cooldown expires

        //isDetecting = true;

        if (!isDetecting) {
          isDetecting = true;
          int startTime = new DateTime.now().millisecondsSinceEpoch;

          Tflite.detectObjectOnFrame(
            bytesList: img.planes.map((plane) {
              return plane.bytes;
            }).toList(),
            model: "SSDMobileNet",
            imageHeight: img.height,
            imageWidth: img.width,
            imageMean: 127.5,
            imageStd: 127.5,
            threshold: 0.6,
            numResultsPerClass: 5,
            rotation:
                widget.rotation + controller!.description.sensorOrientation,
          ).then((recognitions) async {
            ProcessDetectedObjects(img, recognitions, controller, subdir,
                widget.rotation, widget.setRecognitions, widget.model);
            int endTime = new DateTime.now().millisecondsSinceEpoch;
            //print("Detection took ${endTime - startTime}");
            isDetecting = false;
          });
        } else if (subdir != null && !widget.model) {
          var directory;
          if (Platform.isIOS) {
            directory = await getApplicationDocumentsDirectory();
          } else {
            directory = await getExternalStorageDirectory();
          }

          final myImagePath = '${directory.path}/Shots/$subdir';
          final myVideoPath = '${directory.path}/Shots';
          Firebase_backend.makeMovie(myImagePath, myVideoPath, subdir!);
          subdir = null;
        }
      });
    }
  }
}
