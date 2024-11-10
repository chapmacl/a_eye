import 'dart:convert';
import 'dart:io';

import 'package:a_eye/providers/firebase.dart';
import 'package:a_eye/utils/label_map.dart';
import 'package:camera/camera.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as imglib;

DateFormat formatDate = new DateFormat('yyyy-MM-dd_HH:mm');
NumberFormat formatNum = new NumberFormat("0000");
imglib.JpegEncoder encoder = new imglib.JpegEncoder(quality: 80);
late Map labelsMap;
String encodedMap = Settings.getValue('labelsmap', defaultValue: 'default')!;
int imageCount = 1;
int cooldownInit = 200;
bool startCapture = true;
int cooldown = cooldownInit;

ProcessDetectedObjects(
    CameraImage img,
    recognitions,
    CameraController? controller,
    String? subdir,
    int rotation,
    callback,
    bool capture) async {
  List filtered = [];
  for (var obj in recognitions!) {
    // remove any objects that are not set to be detected
    if (labelsMap[obj['detectedClass']]) {
      filtered.add(obj);
    }
  }
  List adjusted = List.from(filtered);
  // Take care to remember android automatically rotates 90, so this might be incorrect on other devices
  if (rotation == 0) {
    // do nothing
  } else if (rotation == 90) {
    for (Map obj in adjusted) {
      var temp = (1.0 - obj['rect']['x']) - obj['rect']['w'];
      obj['rect']['x'] = obj['rect']['y'];
      obj['rect']['y'] = temp;
      temp = obj['rect']['w'];
      obj['rect']['w'] = obj['rect']['h'];
      obj['rect']['h'] = temp;
    }
  } else if (rotation == 180) {
    for (Map obj in adjusted) {
      obj['rect']['x'] = (1.0 - obj['rect']['x']) - obj['rect']['w'];
      obj['rect']['y'] = (1.0 - obj['rect']['y']) - obj['rect']['h'];
    }
  } else if (rotation == 270) {
    for (Map obj in adjusted) {
      var temp = obj['rect']['x'];
      obj['rect']['x'] = (1.0 - obj['rect']['y']) - obj['rect']['h'];
      obj['rect']['y'] = temp;
      temp = obj['rect']['w'];
      obj['rect']['w'] = obj['rect']['h'];
      obj['rect']['h'] = temp;
    }
  }
  callback(adjusted, img.height, img.width);

  if (filtered.isNotEmpty && capture) {
    // Object was detected and model is ready. Restart cooldown timer, begin converting image to save
    cooldown = cooldownInit;
    imglib.Image? buffer = convertImg(img);
    buffer ?? ExportImg(buffer, controller, adjusted, subdir, rotation);
  } else if (!startCapture) {
    cooldown -= 1;
    print(cooldown);
    if (cooldown == 0) {
      // Cooldown timer has reached the threshold, begin new capture folder
      cooldown = cooldownInit;
      startCapture = true;
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
  }
}

ExportImg(imageBytes, CameraController? controller, recognitions,
    String? subdir, int rotation) async {
  bool bbox = Settings.getValue('bbox', defaultValue: true)!;
  bool labels = Settings.getValue('labels', defaultValue: true)!;

  if (encodedMap == 'default') {
    labelsMap = getMap();
  } else {
    labelsMap = json.decode(encodedMap);
  }
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

  imageBytes =
      imglib.copyRotate(imageBytes, controller!.description.sensorOrientation);

  for (var obj in recognitions) {
    var x1, y1, x2, y2, w, h;

    h = imageBytes.height;
    w = imageBytes.width;
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

    if (bbox) {
      // Draw boxes around objects
      imageBytes = imglib.drawRect(imageBytes, x1.round(), y1.round(),
          x2.round(), y2.round(), imglib.getColor(122, 229, 130));
    }
    if (labels) {
      // Label objects
      imageBytes = imglib.drawString(imageBytes, imglib.arial_24, x1.round(),
          y2.round(), obj["detectedClass"],
          color: imglib.getColor(122, 229, 130));
    }
  }

  imageBytes = imglib.copyRotate(imageBytes, rotation);
  List<int> jpeg = encoder.encodeImage(imageBytes);
  String name = '${subdir}_${formatNum.format(imageCount)}';
  imageCount += 1;
  if (imageCount > 999) {
    // if an object is captured for a lengthy period of time, a new directory is automatically created
    imageCount = 1;
    Firebase_backend.makeMovie(myImagePath, myImagePath, subdir!);
    subdir = formatDate.format(DateTime.now());
  }
  var write = new File("$myImagePath/image_$name.jpg")..writeAsBytesSync(jpeg);
  print(write.path);
}

imglib.Image? convertImg(CameraImage image) {
  late imglib.Image? file;

  try {
    if (image.format.group == ImageFormatGroup.yuv420) {
      file = _convertYUV420(image);
    } else if (image.format.group == ImageFormatGroup.bgra8888) {
      file = _convertBGRA8888(image);
    }
  } catch (e) {
    print(">>>>>>>>>>>> ERROR:" + e.toString());
  }
  return file;
}

imglib.Image _convertBGRA8888(CameraImage image) {
  return imglib.Image.fromBytes(
    image.width,
    image.height,
    image.planes[0].bytes,
    format: imglib.Format.bgra,
  );
}

imglib.Image? _convertYUV420(CameraImage image) {
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
