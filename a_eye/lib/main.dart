import 'package:a_eye/app_theme.dart';
import 'package:a_eye/backend.dart';
import 'package:a_eye/settings_screen.dart';
import 'package:bottom_navy_bar/bottom_navy_bar.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:a_eye/file_explorer.dart';
import 'package:flutter/services.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:ndialog/ndialog.dart';
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
            if (!newUser) {
              if (index == 0 && Settings.getValue('newuserfile', true)) {
                Future.delayed(
                    Duration(milliseconds: 100),
                    () => DialogBackground(
                          blur: 2.0,
                          dialog: AlertDialog(
                            title: Text("Photos"),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset('assets/images/hold.gif'),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                      "On this screen you can see all the photos and videos A.Eye. has captured. Tap and hold folders and files to see more options."),
                                ),
                              ],
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: Text("Ok"),
                                onPressed: () async {
                                  await Settings.setValue('newuserfile', false);
                                  Navigator.pop(context);
                                },
                              )
                            ],
                          ),
                        ).show(context,
                            transitionType: DialogTransitionType.Bubble));
              } else if (index == 1 &&
                  Settings.getValue('newusercamera', true)) {
                Future.delayed(
                    Duration(milliseconds: 100),
                    () => DialogBackground(
                          blur: 2.0,
                          dialog: AlertDialog(
                            title: Text("Camera"),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset('assets/images/tap.gif'),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                      "On this screen you can see what A.Eye. is looking at. Tap on Quick Settings to adjust various settings. Don't forget to press the Play button when you're ready for A.Eye to start capturing photos!"),
                                ),
                              ],
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: Text("Ok"),
                                onPressed: () async {
                                  await Settings.setValue(
                                      'newusercamera', false);
                                  Navigator.pop(context);
                                },
                              )
                            ],
                          ),
                        ).show(context,
                            transitionType: DialogTransitionType.Bubble));
              }
            }
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
                          _pageController.nextPage(
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
                            _pageController.nextPage(
                                curve: Curves.easeOut,
                                duration: Duration(milliseconds: 250));
                          }
                        },
                      )
                    ],
                  )),
                  Container(
                      child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/images/charts.gif'),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 16.0, right: 16.0, bottom: 16.0),
                        child: Text(
                          'Done. \n You\'re all ready to start using A.Eye. smart camera. '
                          'It\'s completely free to use locally, and you can upload and store up to 5 captured events in our Cloud. '
                          'The Cloud lets you view captured photos and videos on any device. '
                          'Unlimited Cloud storage is available to subscribers.',
                          textAlign: TextAlign.center,
                          style: AppTheme.subtitle2,
                        ),
                      ),
                      ElevatedButton(
                        child: Text('Let\'s go!'),
                        onPressed: () async {
                          await Settings.setValue('newuser', false);
                          setState(() {
                            newUser = false;
                            _currentIndex = 1;
                            _pageController.jumpTo(1);
                          });
                        },
                      )
                    ],
                  ))
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
