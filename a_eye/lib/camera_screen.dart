import 'dart:async';
import 'package:a_eye/app_theme.dart';
import 'package:a_eye/backend.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:ndialog/ndialog.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:tflite/tflite.dart';
import 'package:wakelock/wakelock.dart';
import 'dart:math' as math;
import 'camera.dart';
import 'bndbox.dart';

const String ssd = "SSD MobileNet";

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  CameraScreen(this.cameras);

  @override
  _CameraScreenState createState() => new _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with TickerProviderStateMixin {
  List<dynamic>? _recognitions;
  int _imageHeight = 0;
  int _imageWidth = 0;
  bool _model = false;
  PanelController _pc = new PanelController();
  late Animation<double> _myAnimation;
  late AnimationController _controller;
  bool blackout = Settings.getValue('blackout', defaultValue: false)!;
  bool bbox = Settings.getValue('bbox', defaultValue: true)!;
  bool labels = Settings.getValue('labels', defaultValue: true)!;
  int? folderCount;
  double zoom = Settings.getValue('zoom', defaultValue: 1.0)!;
  bool isDetecting = false;
  late StreamSubscription<AccelerometerEvent> sub;
  int x = 0;
  int y = 1;
  int z = 0;
  late int rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    _myAnimation = CurvedAnimation(curve: Curves.linear, parent: _controller);
    loadModel();
    sub = accelerometerEvents.listen((AccelerometerEvent event) {
      x = (event.x / 9.81).round();
      y = (event.y / 9.81).round();
      z = (event.z / 9.81).round();
    });
    folderCount = Settings.getValue('folders', defaultValue: 0);
  }

  loadModel() async {
    String? res;
    Tflite.close();
    res = await Tflite.loadModel(
      model: "assets/models/mobilenet_v2_1.0_224_quantized_1_metadata_1.tflite",
      labels: "assets/models/ssd_mobilenet.txt",
      //useGpuDelegate: true,
    );

    print(res);
  }

  setRecognitions(recognitions, imageHeight, imageWidth) {
    setState(() {
      _recognitions = recognitions;
      _imageHeight = imageHeight;
      _imageWidth = imageWidth;
    });
  }

  @override
  void dispose() {
    super.dispose();
    Wakelock.disable();
    sub.cancel();
  }

  int getRotation() {
    if (x == 0 && y == 1) {
      rotation = 0;
    } else if (x == 1 && y == 0) {
      rotation = 270;
    } else if (x == 0 && y == -1) {
      rotation = 180;
    } else if (x == -1 && y == 0) {
      rotation = 90;
    }
    return rotation;
  }

  @override
  Widget build(BuildContext context) {
    Size screen = MediaQuery.of(context).size;
    User? user = Backend.getUser();
    if (user == null) {
      Settings.setValue('drive', false);
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
          backgroundColor: _model ? AppTheme.appBlue : Colors.grey,
          onPressed: () async {
            var answer = await Permission.storage.request();
            if (answer == PermissionStatus.granted) {
              if (!_model) {
                _controller.forward();
              } else {
                _controller.reverse();
              }
              setState(() {
                _model = !_model;
              });
              Wakelock.enable();
            } else if (answer == PermissionStatus.permanentlyDenied) {
              DialogBackground(
                blur: 2.0,
                dialog: AlertDialog(
                  title: Text("Storage"),
                  content: Text(
                      "You need to allow storage permissions to save videos."),
                  actions: <Widget>[
                    TextButton(
                      child: Text("Go to settings"),
                      onPressed: () {
                        Navigator.pop(context);
                        openAppSettings();
                      },
                    ),
                    TextButton(
                      child: Text("Ok"),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    )
                  ],
                ),
              ).show(context, transitionType: DialogTransitionType.Bubble);
            }
          },
          child: AnimatedIcon(
            icon: AnimatedIcons.play_pause,
            progress: _myAnimation,
          )),
      backgroundColor: Colors.white12,
      body: SlidingUpPanel(
        isDraggable: !_model,
        controller: _pc,
        minHeight: 40,
        maxHeight: MediaQuery.of(context).size.height * 0.75,
        header: GestureDetector(
          onTap: () {
            if (!_model) {
              if (_pc.isPanelClosed) {
                _pc.open();
              } else {
                _pc.close();
              }
            }
          },
          child: Container(
              height: 45,
              width: MediaQuery.of(context).size.width,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: !_model
                    ? Text(
                        'Quick Settings',
                        style: AppTheme.body2,
                        textAlign: TextAlign.center,
                      )
                    : null,
              ),
              decoration: BoxDecoration(
                  color: Colors.blueGrey,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24.0),
                    topRight: Radius.circular(24.0),
                  ))),
        ),
        panel: Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
          child: SettingsContainer(
            allowScrollInternally: true,
            children: <Widget>[
              SwitchSettingsTile(
                defaultValue: true,
                settingKey: 'bbox',
                title: 'Bounding Boxes',
                enabledLabel: 'Boxes around objects',
                disabledLabel: 'No boxes around objects',
                leading: Icon(Icons.check_box_outline_blank_rounded),
                onChange: (value) {
                  setState(() {
                    bbox = value;
                  });
                },
              ),
              SwitchSettingsTile(
                defaultValue: true,
                settingKey: 'label',
                title: 'Object Labels',
                enabledLabel: 'Objects will be labeled',
                disabledLabel: 'Objects won\'t be labeled',
                leading: Icon(Icons.description_outlined),
                onChange: (value) {
                  setState(() {
                    labels = value;
                  });
                },
              ),
              SliderSettingsTile(
                title: 'Zoom',
                settingKey: 'zoom',
                defaultValue: 1.0,
                min: 1,
                max: 3,
                step: 1,
                leading: Icon(Icons.zoom_in_outlined),
                onChange: (value) {
                  setState(() {
                    zoom = value;
                  });
                },
              ),
              SwitchSettingsTile(
                defaultValue: false,
                settingKey: 'blackout',
                title: 'Turn off Screen',
                subtitle: 'This setting can conserve energy on certain devices',
                enabledLabel: 'Enabled',
                disabledLabel: 'Disabled',
                leading: Icon(Icons.brightness_6_outlined),
                onChange: (value) {
                  setState(() {
                    blackout = value;
                  });
                },
              ),
              SwitchSettingsTile(
                defaultValue: false,
                settingKey: 'drive',
                title: 'Cloud Storage',
                enabledLabel: 'Enabled',
                disabledLabel: 'Disabled',
                leading: Icon(Icons.cloud_upload_outlined),
                enabled: user == null ? false : true,
                childrenIfEnabled: [
                  SwitchSettingsTile(
                      // TODO if free user is logged in and at limit, show some sort of message
                      defaultValue: false,
                      settingKey: 'onlycloud',
                      title: 'Only Cloud Storage',
                      enabledLabel:
                          'Videos will only be stored in the cloud, and not on device.',
                      disabledLabel:
                          'Videos will be stored on device and in the cloud.',
                      leading: Icon(
                        Icons.folder_open_outlined,
                      ))
                ],
              ),
              Container(
                height: 100,
              )
            ],
          ),
        ),
        backdropEnabled: true,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
        body: Stack(
          children: [
            Camera(widget.cameras, setRecognitions, _model, bbox, labels,
                blackout, zoom, isDetecting, getRotation()),
            if (!blackout)
              BndBox(
                  _recognitions == null ? [] : _recognitions,
                  math.max(_imageHeight, _imageWidth),
                  math.min(_imageHeight, _imageWidth),
                  screen.height,
                  screen.width,
                  bbox,
                  labels),
          ],
        ),
      ),
    );
  }
}
