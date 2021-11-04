import 'package:a_eye/app_theme.dart';
import 'package:a_eye/backend.dart';
import 'package:a_eye/settings_screen.dart';
import 'package:bottom_navy_bar/bottom_navy_bar.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:a_eye/file_explorer.dart';
import 'package:flutter/services.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:permission_handler/permission_handler.dart';
import 'camera_screen.dart';

List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Settings.init();
  await Backend.initializeFirebase();
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error: $e.code\nError Message: $e.message');
  }
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(new MyApp());
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 1;
  PageController _pageController;
  bool newUser;

  @override
  void initState() {
    super.initState();
    newUser = Settings.getValue('newuser', true);
    if (newUser) {
      _currentIndex = 0;
    }
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() => _currentIndex = index);
          },
          children: newUser
              ? [
                  Container(
                      child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/images/detect.gif'),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 16.0, right: 16.0, bottom: 16.0),
                        child: Text(
                          'Welcome to A.Eye. \n\n There are just a few things to do before you\'re ready to go.',
                          textAlign: TextAlign.center,
                          style: AppTheme.title,
                        ),
                      ),
                      ElevatedButton(
                        child: Text('Next'),
                        onPressed: () {
                          _pageController.animateToPage(1,
                              curve: Curves.easeOut,
                              duration: Duration(milliseconds: 250));
                        },
                      )
                    ],
                  )),
                  Container(
                      child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/images/permission.gif'),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 16.0, right: 16.0, bottom: 16.0),
                        child: Text(
                          'In order to use the app, we need permission for the Camera, and Storage.',
                          textAlign: TextAlign.center,
                          style: AppTheme.title,
                        ),
                      ),
                      ElevatedButton(
                        child: Text('Enable'),
                        onPressed: () async {
                          Map<Permission, PermissionStatus> statuses = await [
                            Permission.camera,
                            Permission.storage,
                          ].request();
                          bool permissions = true;
                          for (var status in statuses.values) {
                            if (status != PermissionStatus.granted) {
                              permissions = false;
                            }
                          }
                          if (permissions) {
                            await Settings.setValue('newuser', false);
                            setState(() {
                              newUser = false;
                            });
                          }
                        },
                      )
                    ],
                  )),
                ]
              : [
                  FileScreen(_pageController),
                  CameraScreen(cameras),
                  SettingsArea(),
                ],
        ),
        bottomNavigationBar: BottomNavyBar(
          containerHeight: newUser ? 0 : 60,
          backgroundColor: AppTheme.notWhite,
          selectedIndex: _currentIndex,
          onItemSelected: (index) {
            setState(() => _currentIndex = index);
            _pageController.animateToPage(index,
                curve: Curves.easeOut, duration: Duration(milliseconds: 250));
          },
          items: <BottomNavyBarItem>[
            BottomNavyBarItem(
                icon: Icon(Icons.photo_library_outlined),
                title: Text(
                  'Photos',
                  style: AppTheme.title2,
                ),
                activeColor: AppTheme.appIndigo,
                textAlign: TextAlign.center),
            BottomNavyBarItem(
                icon: Icon(Icons.videocam_rounded),
                title: Text(
                  'Smart Cam',
                  style: AppTheme.title2,
                ),
                activeColor: AppTheme.appIndigo,
                textAlign: TextAlign.center),
            BottomNavyBarItem(
                icon: Icon(Icons.tune_rounded),
                title: Text(
                  'Settings',
                  style: AppTheme.title2,
                ),
                activeColor: AppTheme.appIndigo,
                textAlign: TextAlign.center),
          ],
        ));
  }
}
