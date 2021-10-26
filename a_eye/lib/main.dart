import 'package:a_eye/app_theme.dart';
import 'package:a_eye/backend.dart';
import 'package:a_eye/settings_screen.dart';
import 'package:bottom_navy_bar/bottom_navy_bar.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:a_eye/file_explorer.dart';
import 'package:flutter/services.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';

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

  @override
  void initState() {
    super.initState();
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
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() => _currentIndex = index);
          },
          children: [
            FileScreen(_pageController),
            CameraScreen(cameras),
            SettingsArea(),
          ],
        ),
        bottomNavigationBar: BottomNavyBar(
          containerHeight: 60,
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
