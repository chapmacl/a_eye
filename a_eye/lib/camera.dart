import 'dart:convert';
import 'package:a_eye/backend.dart';
import 'package:a_eye/label_map.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math' as math;
import 'package:image/image.dart' as imglib;
import 'dart:io';
import 'app_theme.dart';

const String ssd = "SSD MobileNet";
const String yolo = "Tiny YOLOv2";

typedef void Callback(List<dynamic> list, int h, int w);

// ignore: must_be_immutable
class Camera extends StatefulWidget {
  final List<CameraDescription> cameras;
  final Callback setRecognitions;
  bool model;
  bool bbox;
  bool labels;
  bool blackout;

  double zoom;
  bool isDetecting;
  int rotation;

  Camera(this.cameras, this.setRecognitions, this.model, this.bbox, this.labels,
      this.blackout, this.zoom, this.isDetecting, this.rotation);

  @override
  _CameraState createState() => new _CameraState();
}

class _CameraState extends State<Camera> {
  CameraController? controller;
  bool isDetecting = false;
  // TODO play with this quality number
  imglib.JpegEncoder encoder = new imglib.JpegEncoder(quality: 80);
  DateFormat formatDate = new DateFormat('yyyy-MM-dd_HH:mm');
  NumberFormat formatNum = new NumberFormat("0000");
  late int cooldown;
  int cooldownInit = 200;
  bool startCapture = true;
  String? subdir;
  late int imageCount;
  late Map labelsMap;
  String encodedMap = Settings.getValue('labelsmap', defaultValue: 'default')!;
  bool? permission;

  @override
  void initState() {
    super.initState();
    cooldown = cooldownInit;
    imageCount = 1;
    if (encodedMap == 'default') {
      labelsMap = getMap();
    } else {
      labelsMap = json.decode(encodedMap);
    }
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
        Backend.makeMovie(myImagePath, myVideoPath, subdir!);
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

      // controller!.startImageStream((CameraImage img) async {
      //   // TODO create method with Timer(const Duration(seconds: 10), () => callback());
      //   // to only check every few seconds by setting isDetecting to true
      //   // once an object is detected automatically shut off the sleep function until cooldown expires

      //   //isDetecting = true;

      //   if (!isDetecting) {
      //     isDetecting = true;
      //     int startTime = new DateTime.now().millisecondsSinceEpoch;

      //     Tflite.detectObjectOnFrame(
      //       bytesList: img.planes.map((plane) {
      //         return plane.bytes;
      //       }).toList(),
      //       model: "SSDMobileNet",
      //       imageHeight: img.height,
      //       imageWidth: img.width,
      //       imageMean: 127.5,
      //       imageStd: 127.5,
      //       threshold: 0.6,
      //       numResultsPerClass: 5,
      //       rotation:
      //           widget.rotation + controller!.description.sensorOrientation,
      //     ).then((recognitions) async {
      //       List filtered = [];
      //       for (var obj in recognitions!) {
      //         // remove any objects that are not set to be detected
      //         if (labelsMap[obj['detectedClass']]) {
      //           filtered.add(obj);
      //         }
      //       }
      //       List adjusted = List.from(filtered);
      //       if (mounted) {
      //         // Take care to remember android automatically rotates 90, so this might be incorrect on other devices
      //         if (widget.rotation == 0) {
      //           // do nothing
      //         } else if (widget.rotation == 90) {
      //           for (Map obj in adjusted) {
      //             var temp = (1.0 - obj['rect']['x']) - obj['rect']['w'];
      //             obj['rect']['x'] = obj['rect']['y'];
      //             obj['rect']['y'] = temp;
      //             temp = obj['rect']['w'];
      //             obj['rect']['w'] = obj['rect']['h'];
      //             obj['rect']['h'] = temp;
      //           }
      //         } else if (widget.rotation == 180) {
      //           for (Map obj in adjusted) {
      //             obj['rect']['x'] =
      //                 (1.0 - obj['rect']['x']) - obj['rect']['w'];
      //             obj['rect']['y'] =
      //                 (1.0 - obj['rect']['y']) - obj['rect']['h'];
      //           }
      //         } else if (widget.rotation == 270) {
      //           for (Map obj in adjusted) {
      //             var temp = obj['rect']['x'];
      //             obj['rect']['x'] =
      //                 (1.0 - obj['rect']['y']) - obj['rect']['h'];
      //             obj['rect']['y'] = temp;
      //             temp = obj['rect']['w'];
      //             obj['rect']['w'] = obj['rect']['h'];
      //             obj['rect']['h'] = temp;
      //           }
      //         }
      //         widget.setRecognitions(adjusted, img.height, img.width);
      //       }
      //       if (filtered.isNotEmpty && widget.model) {
      //         // Object was detected and model is ready. Restart cooldown timer, begin converting image to save
      //         cooldown = cooldownInit;
      //         convertImg(img, adjusted);
      //       } else if (!startCapture) {
      //         cooldown -= 1;
      //         print(cooldown);
      //         if (cooldown == 0) {
      //           // Cooldown timer has reached the threshold, begin new capture folder
      //           cooldown = cooldownInit;
      //           startCapture = true;
      //           var directory;
      //           if (Platform.isIOS) {
      //             directory = await getApplicationDocumentsDirectory();
      //           } else {
      //             directory = await getExternalStorageDirectory();
      //           }

      //           final myImagePath = '${directory.path}/Shots/$subdir';
      //           final myVideoPath = '${directory.path}/Shots';
      //           Backend.makeMovie(myImagePath, myVideoPath, subdir!);
      //           subdir = null;
      //         }
      //       }
      //       int endTime = new DateTime.now().millisecondsSinceEpoch;
      //       //print("Detection took ${endTime - startTime}");
      //       isDetecting = false;
      //     });
      //   } else if (subdir != null && !widget.model) {
      //     var directory;
      //     if (Platform.isIOS) {
      //       directory = await getApplicationDocumentsDirectory();
      //     } else {
      //       directory = await getExternalStorageDirectory();
      //     }

      //     final myImagePath = '${directory.path}/Shots/$subdir';
      //     final myVideoPath = '${directory.path}/Shots';
      //     Backend.makeMovie(myImagePath, myVideoPath, subdir!);
      //     subdir = null;
      //   }
      // });
    }
  }

  convertImg(CameraImage img, recognitions) async {
    if (startCapture) {
      // At the beginning of a new capture session, all variables are initialized
      subdir = formatDate.format(DateTime.now());
      startCapture = false;
      imageCount = 1;
    }

    var directory;
    if (Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
    } else {
      directory = await getExternalStorageDirectory();
    }
    final myImagePath = '${directory.path}/Shots/$subdir';
    bool exists = await Directory(myImagePath).exists();
    if (!exists) {
      await new Directory(myImagePath).create(recursive: true);
    }
    late imglib.Image file;

    try {
      if (img.format.group == ImageFormatGroup.yuv420) {
        file = _convertYUV420(img);
      } else if (img.format.group == ImageFormatGroup.bgra8888) {
        file = _convertBGRA8888(img);
      }
    } catch (e) {
      print(">>>>>>>>>>>> ERROR:" + e.toString());
    }

    file = imglib.copyRotate(file, controller!.description.sensorOrientation);

    for (var obj in recognitions) {
      var x1, y1, x2, y2, w, h;

      h = file.height;
      w = file.width;
      x1 = obj["rect"]["x"] * w;
      y1 = obj["rect"]["y"] * h;
      x2 = x1 + obj["rect"]["w"] * w;
      y2 = y1 + obj["rect"]["h"] * h;

      // TODO find a more elegant solution to this...
      // if (widget.rotation == 0) {
      //   x1 = obj["rect"]["x"] * w;
      //   y1 = obj["rect"]["y"] * h;
      //   x2 = x1 + obj["rect"]["w"] * w;
      //   y2 = y1 + obj["rect"]["h"] * h;
      // } else if (widget.rotation == 180) {
      //   x1 = (1 - obj["rect"]["x"]) * w - obj["rect"]["w"] * w;
      //   y1 = (1 - obj["rect"]["y"]) * h - obj["rect"]["h"] * h;
      //   x2 = x1 + obj["rect"]["w"] * w;
      //   y2 = y1 + obj["rect"]["h"] * h;
      // } else if (widget.rotation == 90) {
      //   x1 = (1 - obj["rect"]["y"]) * w - obj["rect"]["w"] * w;
      //   y1 = obj["rect"]["x"] * h;
      //   x2 = x1 + obj["rect"]["w"] * w;
      //   y2 = y1 + obj["rect"]["h"] * h;
      // } else if (widget.rotation == 270) {
      //   x1 = obj["rect"]["y"] * w;
      //   y1 = (1 - obj["rect"]["x"]) * h - obj["rect"]["h"] * h;
      //   x2 = x1 + obj["rect"]["w"] * w;
      //   y2 = y1 + obj["rect"]["h"] * h;
      // }
      if (widget.bbox) {
        // Draw boxes around objects
        file = imglib.drawRect(file, x1.round(), y1.round(), x2.round(),
            y2.round(), imglib.getColor(122, 229, 130));
      }
      if (widget.labels) {
        // Label objects
        file = imglib.drawString(
            file, imglib.arial_24, x1.round(), y2.round(), obj["detectedClass"],
            color: imglib.getColor(122, 229, 130));
      }
    }

    file = imglib.copyRotate(file, widget.rotation);
    List<int> jpeg = encoder.encodeImage(file);
    String name = '${subdir}_${formatNum.format(imageCount)}';
    imageCount += 1;
    if (imageCount > 999) {
      // if an object is captured for a lengthy period of time, a new directory is automatically created
      imageCount = 1;
      Backend.makeMovie(myImagePath, myImagePath, subdir!);
      subdir = formatDate.format(DateTime.now());
    }
    var write = new File("$myImagePath/image_$name.jpg")
      ..writeAsBytesSync(jpeg);
    print(write.path);
  }

  imglib.Image _convertBGRA8888(CameraImage image) {
    return imglib.Image.fromBytes(
      image.width,
      image.height,
      image.planes[0].bytes,
      format: imglib.Format.bgra,
    );
  }

  _convertYUV420(CameraImage image) {
    try {
      final int width = image.width;
      final int height = image.height;
      final int uvRowStride = image.planes[1].bytesPerRow;
      final int? uvPixelStride = image.planes[1].bytesPerPixel;

      imglib.Image img = imglib.Image(width, height); // Create Image buffer

      // Fill image buffer with plane[0] from YUV420_888
      for (int x = 0; x < width; x++) {
        for (int y = 0; y < height; y++) {
          final int uvIndex =
              uvPixelStride! * (x / 2).floor() + uvRowStride * (y / 2).floor();
          final int index = y * width + x;

          final yp = image.planes[0].bytes[index];
          final up = image.planes[1].bytes[uvIndex];
          final vp = image.planes[2].bytes[uvIndex];
          // Calculate pixel color
          int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
          int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
              .round()
              .clamp(0, 255);
          int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);
          // color: 0x FF  FF  FF  FF
          //           A   B   G   R
          img.data[index] = (0xFF << 24) | (b << 16) | (g << 8) | r;
        }
      }

      return img;
    } catch (e) {
      print(">>>>>>>>>>>> ERROR:" + e.toString());
    }
    return null;
  }
}
