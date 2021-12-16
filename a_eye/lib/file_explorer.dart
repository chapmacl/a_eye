import 'dart:io';
import 'package:a_eye/app_theme.dart';
import 'package:a_eye/backend.dart';
import 'package:a_eye/video_view.dart';
import 'package:a_eye/string_functions.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:focused_menu/focused_menu.dart';
import 'package:focused_menu/modals.dart';
import 'package:ndialog/ndialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

// ignore: must_be_immutable
class FileScreen extends StatefulWidget {
  PageController pageController;

  FileScreen(this.pageController);

  @override
  _FileScreenState createState() => _FileScreenState();
}

class _FileScreenState extends State<FileScreen> {
  var _videoDir;
  String title = '';
  List subdirs = [];
  bool isLocal;
  ScrollController controller = ScrollController();
  final FlutterFFmpeg _flutterFFmpeg = new FlutterFFmpeg();
  int folderCount;
  PanelController _pc = new PanelController();

  bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    if (subdirs.length > 0) {
      var last = subdirs.last;
      subdirs.removeLast();
      if (last == 'photo') {
        return false;
      } else if (last == 'root') {
        setState(() {
          _videoDir = 'null';
          isLocal = null;
        });
        return true;
      } else {
        updateDir(last);
        return true;
      }
    } else {
      return false;
    }
  }

  void customBack() {
    if (subdirs.length > 0) {
      var last = subdirs.last;
      subdirs.removeLast();
      if (last == 'photo') {
        Navigator.pop(context);
      } else if (last == 'root') {
        setState(() {
          _videoDir = 'null';
          isLocal = null;
        });
      } else {
        updateDir(last);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    BackButtonInterceptor.add(myInterceptor);
    _videoDir = 'null';
    isLocal = null;
    folderCount = Settings.getValue('folders', 0);
  }

  @override
  void dispose() {
    BackButtonInterceptor.remove(myInterceptor);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppTheme.notWhite,
        title: Text(
          // internal storage uses directories, so the name is known before pulling, whereas with cloud the name is only available after the https call
          getTitle(_videoDir),
          style: AppTheme.title,
        ),
        leading: isLocal == null
            ? Container()
            : IconButton(
                icon: Icon(Icons.arrow_back_ios_rounded,
                    color: AppTheme.appIndigo),
                onPressed: () => customBack(),
              ),
        actions: [
          if (isLocal != null && _videoDir != 'cloud')
            IconButton(
                icon: Icon(
                  Icons.delete,
                  color: AppTheme.appIndigo,
                ),
                onPressed: () async {
                  bool result = await DialogBackground(
                    blur: 2.0,
                    dialog: AlertDialog(
                      title: Text("Delete all photos"),
                      content: Text("Are you sure?"),
                      actions: <Widget>[
                        TextButton(
                          child: Text("No"),
                          onPressed: () {
                            Navigator.pop(context, false);
                          },
                        ),
                        TextButton(
                          child: Text("Yes"),
                          onPressed: () {
                            Navigator.pop(context, true);
                          },
                        )
                      ],
                    ),
                  ).show(context, transitionType: DialogTransitionType.Bubble);
                  if (result) {
                    var path = _videoDir;
                    Fluttertoast.showToast(
                        msg: "Files are being deleted...",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.CENTER,
                        timeInSecForIosWeb: 1,
                        backgroundColor: AppTheme.notWhite,
                        textColor: AppTheme.appIndigo,
                        fontSize: 16.0);
                    delete(path);
                  }
                }),
          SizedBox(
            width: 16,
          )
        ],
      ),
      backgroundColor: AppTheme.nearlyWhite,
      body: SlidingUpPanel(
          color: AppTheme.notWhite,
          controller: _pc,
          minHeight: isLocal == true ? 0 : 40,
          maxHeight: MediaQuery.of(context).size.height * 0.3,
          backdropEnabled: true,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.0),
            topRight: Radius.circular(24.0),
          ),
          panel: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                      folderCount < 0
                          ? 'Thank you for being a Pro User. All features are available, without restrictions or limits.'
                          : 'As a free user you can use however much space is available on your phone, but you only have 5 free folders for cloud storage. Cloud storage is useful for securing your data and being able to access it from any mobile device through this app. \n\nPro users can take full advantage of the app and have unlimited Cloud storage.',
                      textAlign: TextAlign.center),
                ),
                folderCount < 0
                    ? SizedBox()
                    : Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: ElevatedButton(
                          child: Text('Unlock Pro Features'),
                          onPressed: () async {
                            // TODO revenue cat logic here
                          },
                        ),
                      )
              ],
            ),
          ),
          header: GestureDetector(
              onTap: () {
                if (_pc.isPanelClosed) {
                  _pc.open();
                } else {
                  _pc.close();
                }
              },
              child: Container(
                  height: 45,
                  width: MediaQuery.of(context).size.width,
                  child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        folderCount < 0
                            ? 'Premium User'
                            : folderCount == 0
                                ? '5 Free Cloud Folders remaining'
                                : folderCount < 4
                                    ? '${5 - folderCount} Free Cloud Folders remaining'
                                    : folderCount < 5
                                        ? '1 Free Cloud Folder remaining'
                                        : 'No Free Cloud Folders remaining',
                        style: AppTheme.body2,
                        textAlign: TextAlign.center,
                      )),
                  decoration: BoxDecoration(
                      color: Colors.blueGrey,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24.0),
                        topRight: Radius.circular(24.0),
                      )))),
          body: _videoDir == null
              ? Center(
                  child: SpinKitFadingGrid(
                  color: AppTheme.appIndigo,
                  size: 100,
                ))
              : isLocal == null
                  ? rootGrid()
                  : Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        height: MediaQuery.of(context).size.height -
                            (AppBar().preferredSize.height + 40 + 60) * 1.1,
                        child: isLocal
                            ? VideoGrid(_videoDir)
                            : cloudImageGrid(_videoDir),
                      ),
                    )),
    );
  }

  getDir() async {
    if (isLocal) {
      var directory;
      if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getExternalStorageDirectory();
      }
      final myImagePath = '${directory.path}/Shots';
      // check if the base directory exists for the app
      var exists = await Directory(myImagePath).exists();
      if (exists) {
        _videoDir = myImagePath;
      } else {
        // first time, create base directory
        await new Directory(myImagePath).create(recursive: true);
        _videoDir = myImagePath;
      }
    } else {
      _videoDir = 'cloud';
    }
    setState(() {});
  }

  void updateDir(String dir) {
    setState(() {
      _videoDir = dir;
    });
  }

// TODO update folders count here
  void delete(var path) async {
    updateDir(null);
    if (isLocal) {
      Directory dir = new Directory(path);
      await dir.delete(recursive: true);
      isLocal = null;
    } else {
      await Backend.deleteFile(path);
    }

    updateDir(subdirs.last);
    subdirs.removeLast();
  }

  Widget VideoGrid(String directory) {
    // TODO maybe a try catch, on error return to root grid and hope for the best
    var dir = new Directory(directory);
    var videoList =
        dir.listSync().map((item) => item.path).toList(growable: false);

    var toBeRemoved =
        videoList.where((element) => element.contains('null')).toList();

    videoList =
        videoList.where((element) => !element.contains('null')).toList();

    if (videoList.isNotEmpty) {
      videoList.sort((b, a) => a.compareTo(b));
    }

    // Fairly hacky solution. Sometimes folders will be leftover when switching
    // between pages quickly. Must not let the user see them...
    if (toBeRemoved.isNotEmpty) {
      for (var directory in toBeRemoved) {
        new Directory(directory).delete(recursive: true);
      }
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Container(
          color: AppTheme.nearlyWhite,
          child: videoList.isEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search,
                      color: AppTheme.appIndigo,
                    ),
                    Text(
                      "No Photos yet...",
                      style: AppTheme.title2,
                    )
                  ],
                )
              : DraggableScrollbar.semicircle(
                  alwaysVisibleScrollThumb: true,
                  controller: controller,
                  labelConstraints:
                      BoxConstraints.tightFor(width: 80.0, height: 30.0),
                  backgroundColor: AppTheme.notWhite,
                  child: GridView.builder(
                    shrinkWrap: true,
                    controller: controller,
                    physics: BouncingScrollPhysics(),
                    itemCount: videoList.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3),
                    itemBuilder: (context, index) {
                      List filePath = videoList[index].split('/');
                      String name = filePath.last;
                      String folderName = name;

                      if (videoList[index].contains('.mp4')) {
                        folderName = name.split('_').first;
                      }

                      return FocusedMenuHolder(
                        menuWidth: MediaQuery.of(context).size.width * 0.50,
                        blurSize: 5.0,
                        menuItemExtent: 45,
                        menuBoxDecoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius:
                                BorderRadius.all(Radius.circular(15.0))),
                        duration: Duration(milliseconds: 100),
                        animateMenuItems: true,
                        blurBackgroundColor: Colors.black54,
                        openWithTap: false,
                        menuOffset: 10.0,
                        bottomOffsetHeight: 80.0,
                        menuItems: <FocusedMenuItem>[
                          FocusedMenuItem(
                              title: Text("Share"),
                              trailingIcon: Icon(Icons.share),
                              onPressed: () {
                                var text = dateToString(name);
                                Share.shareFiles([videoList[index]],
                                    text: text);
                              }),
                          if (!videoList[index].contains('.mp4'))
                            FocusedMenuItem(
                                title: Text("Backup data"),
                                trailingIcon: Icon(Icons.cloud_upload_rounded),
                                onPressed: () async {
                                  var videoDir =
                                      new Directory(videoList[index]);
                                  var videoPaths = videoDir
                                      .listSync()
                                      .map((item) => item.path)
                                      .toList(growable: false);
                                  if (videoPaths.isNotEmpty) {
                                    // get root dir id
                                    Fluttertoast.showToast(
                                        msg: "Files are being uploaded...",
                                        toastLength: Toast.LENGTH_SHORT,
                                        gravity: ToastGravity.CENTER,
                                        timeInSecForIosWeb: 1,
                                        backgroundColor: AppTheme.notWhite,
                                        textColor: AppTheme.appIndigo,
                                        fontSize: 16.0);
                                  }
                                  // loop the list and upload each file
                                  for (var path in videoPaths) {
                                    await Backend.uploadFile(
                                        File(path), folderName);
                                  }
                                }),
                          FocusedMenuItem(
                              title: Text(
                                "Delete",
                                style: TextStyle(color: Colors.redAccent),
                              ),
                              trailingIcon: Icon(
                                Icons.delete,
                                color: Colors.redAccent,
                              ),
                              onPressed: () async {
                                bool result = await DialogBackground(
                                  blur: 2.0,
                                  dialog: AlertDialog(
                                    title: Text("Delete"),
                                    content: Text("Are you sure?"),
                                    actions: <Widget>[
                                      TextButton(
                                        child: Text("No"),
                                        onPressed: () {
                                          Navigator.pop(context, false);
                                        },
                                      ),
                                      TextButton(
                                        child: Text("Yes"),
                                        onPressed: () {
                                          Navigator.pop(context, true);
                                        },
                                      )
                                    ],
                                  ),
                                ).show(context,
                                    transitionType:
                                        DialogTransitionType.Bubble);
                                if (result) {
                                  // Adds current dir, then force to null to trigger loading animation. After deletion current directory is reloaded
                                  subdirs.add(_videoDir);
                                  delete(videoList[index]);
                                } else {
                                  print('else');
                                }
                              }),
                        ],
                        onPressed: () {},
                        child:
                            // TODO display names under video
                            Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: InkWell(
                              onTap: () => {
                                    videoList[index].endsWith('.mp4')
                                        ? {
                                            subdirs.add('photo'),
                                            Navigator.of(context)
                                                .push(MaterialPageRoute(
                                                    builder: (context) =>
                                                        VideoScreen(
                                                            videoList[index],
                                                            isLocal)))
                                                .then((value) {
                                              if (value == 'pop') {
                                                subdirs.removeLast();
                                              } else if (value == 'delete') {
                                                subdirs.removeLast();
                                                subdirs.add(_videoDir);
                                                delete(videoList[index]);
                                              }
                                            })
                                          }
                                        : {
                                            subdirs.add(_videoDir),
                                            updateDir(videoList[index])
                                          }
                                  },
                              child: videoList[index].endsWith('.mp4')
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          // TODO this
                                          // imageBytes != null
                                          //     ? Image.memory(
                                          //         imageBytes,
                                          //         fit: BoxFit.fill,
                                          //       )
                                          //     : Container(),
                                          Center(
                                            child: CircleAvatar(
                                              backgroundColor:
                                                  Colors.white.withOpacity(0.8),
                                              radius: 25,
                                              child: Icon(
                                                Icons.play_circle_fill_rounded,
                                                size: 50,
                                                color: Colors.blueGrey
                                                    .withOpacity(0.8),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                          Icon(
                                            Icons.perm_media_outlined,
                                            color: AppTheme.appIndigo,
                                            size: 50,
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              dateToString(name),
                                              style: AppTheme.body1,
                                              textAlign: TextAlign.center,
                                            ),
                                          )
                                        ])),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }

  Widget rootGrid() {
    User user;
    return Container(
        color: AppTheme.nearlyWhite,
        child: GridView.count(
          padding: const EdgeInsets.all(8.0),
          crossAxisCount: 2,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: InkWell(
                onTap: () => {
                  subdirs.add('root'),
                  setState(() {
                    _videoDir = null;
                    isLocal = true;
                  }),
                  getDir()
                },
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.perm_media_outlined,
                        color: AppTheme.appIndigo,
                        size: 50,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Internal Storage",
                          style: AppTheme.body1,
                          textAlign: TextAlign.center,
                        ),
                      )
                    ]),
              ),
            ),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: InkWell(
                onTap: () async => {
                  user = Backend.getUser(),
                  if (user == null)
                    {
                      DialogBackground(
                        blur: 2.0,
                        dialog: AlertDialog(
                          title: Text("Cloud Storage"),
                          content: Text(
                              "You need to be signed in before using cloud storage."),
                          actions: <Widget>[
                            TextButton(
                              child: Text("Sign in"),
                              onPressed: () {
                                Navigator.pop(context);
                                widget.pageController.jumpToPage(2);
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
                      ).show(context,
                          transitionType: DialogTransitionType.Bubble),
                    }
                  else
                    {
                      subdirs.add('root'),
                      setState(() {
                        _videoDir = null;
                        isLocal = false;
                      }),
                      getDir()
                    }
                },
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        color: AppTheme.appIndigo,
                        size: 50,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Cloud Storage",
                          style: AppTheme.body1,
                          textAlign: TextAlign.center,
                        ),
                      )
                    ]),
              ),
            )
          ],
        ));
  }

  Future getCloudData(String dir) async {
    var resultMap;
    if (dir == 'cloud') {
      resultMap = await Backend.getFolders();
    } else {
      resultMap = await Backend.getFiles(dir);
    }
    return resultMap;
  }

  Widget cloudImageGrid(String dir) {
    // TODO somehow separate videos by device, might need to change cloud layout
    List directory;
    Map results;
    return FutureBuilder(
      future: getCloudData(dir),
      builder: (context, dataSnapshot) {
        if (dataSnapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: SpinKitFadingGrid(
            color: AppTheme.appIndigo,
            size: 100,
          ));
        } else {
          if (dataSnapshot.error != null) {
            return Center(
              child: Text(dataSnapshot.error.toString()),
            );
          } else {
            results = dataSnapshot.data;
            directory = results.keys.toList();
            directory.sort((a, b) => b.toString().compareTo(a.toString()));
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Container(
                  color: AppTheme.nearlyWhite,
                  child: directory.isEmpty
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search,
                              color: AppTheme.appIndigo,
                            ),
                            Text(
                              "No Photos yet...",
                              style: AppTheme.title2,
                            )
                          ],
                        )
                      : DraggableScrollbar.semicircle(
                          controller: controller,
                          labelConstraints: BoxConstraints.tightFor(
                              width: 80.0, height: 30.0),
                          backgroundColor: AppTheme.notWhite,
                          child: GridView.builder(
                            controller: controller,
                            physics: BouncingScrollPhysics(),
                            itemCount: directory.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3),
                            itemBuilder: (context, index) {
                              return FocusedMenuHolder(
                                menuWidth:
                                    MediaQuery.of(context).size.width * 0.50,
                                blurSize: 5.0,
                                menuItemExtent: 45,
                                menuBoxDecoration: BoxDecoration(
                                    color: Colors.grey,
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(15.0))),
                                duration: Duration(milliseconds: 100),
                                animateMenuItems: true,
                                blurBackgroundColor: Colors.black54,
                                openWithTap: false,
                                menuOffset: 10.0,
                                bottomOffsetHeight: 80.0,
                                menuItems: <FocusedMenuItem>[
                                  FocusedMenuItem(
                                      title: Text("Download"),
                                      trailingIcon:
                                          Icon(Icons.download_rounded),
                                      onPressed: () async {
                                        Fluttertoast.showToast(
                                            msg: "Downloading...",
                                            toastLength: Toast.LENGTH_SHORT,
                                            gravity: ToastGravity.CENTER,
                                            timeInSecForIosWeb: 1,
                                            backgroundColor: AppTheme.notWhite,
                                            textColor: AppTheme.appIndigo,
                                            fontSize: 16.0);

                                        // TODO add another downloader option
                                        // if (directory[index].endsWith('.mp4')) {
                                        //   await ImageDownloader.downloadImage(
                                        //       results[directory[index]]);
                                        // }
                                      }),
                                  FocusedMenuItem(
                                      title: Text(
                                        "Delete",
                                        style:
                                            TextStyle(color: Colors.redAccent),
                                      ),
                                      trailingIcon: Icon(
                                        Icons.delete,
                                        color: Colors.redAccent,
                                      ),
                                      onPressed: () async {
                                        bool result = await DialogBackground(
                                          blur: 2.0,
                                          dialog: AlertDialog(
                                            title: Text("Delete"),
                                            content: Text("Are you sure?"),
                                            actions: <Widget>[
                                              TextButton(
                                                child: Text("No"),
                                                onPressed: () {
                                                  Navigator.pop(context, false);
                                                },
                                              ),
                                              TextButton(
                                                child: Text("Yes"),
                                                onPressed: () {
                                                  Navigator.pop(context, true);
                                                },
                                              )
                                            ],
                                          ),
                                        ).show(context,
                                            transitionType:
                                                DialogTransitionType.Bubble);
                                        if (result) {
                                          // Add current dir, then force to null to trigger loading animation. After deletion current directory is reloaded
                                          subdirs.add(_videoDir);
                                          delete(results[directory[index]]);
                                        } else {
                                          print('else');
                                        }
                                      }),
                                ],
                                onPressed: () {},
                                child: Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: InkWell(
                                      onTap: () => {
                                            directory[index].endsWith('.mp4')
                                                ? {
                                                    subdirs.add('photo'),
                                                    Navigator.of(context)
                                                        .push(MaterialPageRoute(
                                                            builder: (context) =>
                                                                VideoScreen(
                                                                    results[directory[
                                                                        index]],
                                                                    isLocal)))
                                                        .then((value) {
                                                      if (value == 'pop') {
                                                        subdirs.removeLast();
                                                      } else if (value ==
                                                          'delete') {
                                                        subdirs.removeLast();
                                                        subdirs.add(_videoDir);
                                                        delete(
                                                            directory[index]);
                                                      }
                                                    })
                                                  }
                                                : {
                                                    subdirs.add(_videoDir),
                                                    updateDir(directory[index])
                                                  }
                                          },
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            // Image.network(
                                            //   // TODO thumbnail
                                            //   results[directory[1]],
                                            //   fit: BoxFit.cover,
                                            // ),
                                            Center(
                                              child: CircleAvatar(
                                                backgroundColor: Colors.white
                                                    .withOpacity(0.8),
                                                radius: 25,
                                                child: Icon(
                                                  Icons
                                                      .play_circle_fill_rounded,
                                                  size: 50,
                                                  color: Colors.blueGrey
                                                      .withOpacity(0.8),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ),
            );
          }
        }
      },
    );
  }
}
