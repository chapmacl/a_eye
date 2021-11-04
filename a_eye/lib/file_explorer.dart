import 'dart:io';
import 'package:a_eye/app_theme.dart';
import 'package:a_eye/backend.dart';
import 'package:a_eye/photo_view.dart';
import 'package:a_eye/string_functions.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
import 'package:image_downloader/image_downloader.dart';
import 'package:ndialog/ndialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// ignore: must_be_immutable
class FileScreen extends StatefulWidget {
  PageController pageController;

  FileScreen(this.pageController);

  @override
  _FileScreenState createState() => _FileScreenState();
}

class _FileScreenState extends State<FileScreen> {
  var _photoDir;
  String title = '';
  List subdirs = [];
  bool isLocal;
  ScrollController controller = ScrollController();
  final FlutterFFmpeg _flutterFFmpeg = new FlutterFFmpeg();
  int folderCount;

  bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    if (subdirs.length > 0) {
      var last = subdirs.last;
      subdirs.removeLast();
      if (last == 'photo') {
        return false;
      } else if (last == 'root') {
        setState(() {
          _photoDir = 'null';
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
          _photoDir = 'null';
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
    _photoDir = 'null';
    isLocal = null;
    folderCount = Settings.getValue('folders', 0);
    if (Settings.getValue('newuserfile', true)) {
      Future.delayed(
          Duration.zero,
          () => DialogBackground(
                blur: 2.0,
                dialog: AlertDialog(
                  title: Text("Photos"),
                  content: Stack(
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
              ).show(context, transitionType: DialogTransitionType.Bubble));
    }
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
          getTitle(_photoDir),
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
          if (isLocal != null && _photoDir != 'cloud')
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
                    var path = _photoDir;
                    delete(path);
                  }
                }),
          SizedBox(
            width: 16,
          )
        ],
      ),
      backgroundColor: AppTheme.nearlyWhite,
      body: Center(
        child: Container(
            child: _photoDir == null
                ? Center(
                    child: SpinKitFadingGrid(
                    color: AppTheme.appIndigo,
                    size: 100,
                  ))
                : isLocal == null
                    ? rootGrid()
                    : isLocal
                        ? imageGrid(_photoDir)
                        : cloudImageGrid(_photoDir)),
      ),
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
        _photoDir = myImagePath;
      } else {
        // first time, create base directory
        await new Directory(myImagePath).create(recursive: true);
        _photoDir = myImagePath;
      }
    } else {
      _photoDir = 'cloud';
    }
    setState(() {});
  }

  void updateDir(String dir) {
    setState(() {
      _photoDir = dir;
    });
  }

  void delete(var path) async {
    updateDir(null);
    if (isLocal) {
      if (path.endsWith('.jpg')) {
        File file = new File(path);
        await file.delete();
      } else {
        Directory dir = new Directory(path);
        await dir.delete(recursive: true);

        isLocal = null;
      }
    } else {
      await Backend.deleteFile(path);
    }

    updateDir(subdirs.last);
    subdirs.removeLast();
  }

  Widget imageGrid(String directory) {
    var dir = new Directory(directory);
    var imageList =
        dir.listSync().map((item) => item.path).toList(growable: false);

    if (imageList.isNotEmpty) {
      imageList.sort((b, a) => a.compareTo(b));
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        color: AppTheme.nearlyWhite,
        child: imageList.isEmpty
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
                labelConstraints:
                    BoxConstraints.tightFor(width: 80.0, height: 30.0),
                backgroundColor: AppTheme.notWhite,
                child: GridView.builder(
                  controller: controller,
                  physics: BouncingScrollPhysics(),
                  itemCount: imageList.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3),
                  itemBuilder: (context, index) {
                    List filePath = imageList[index].split('/');
                    String name = filePath.last;
                    String folderName = name;
                    if (name.endsWith('.jpg')) {
                      folderName = filePath[filePath.length - 2];
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
                        if (name.endsWith('.jpg') || name.endsWith('.mp4')) ...[
                          FocusedMenuItem(
                              title: Text("Share"),
                              trailingIcon: Icon(Icons.share),
                              onPressed: () {
                                var text = dateToString(name);
                                Share.shareFiles([imageList[index]],
                                    text: text);
                              })
                        ] else ...[
                          FocusedMenuItem(
                              title: Text("Create Video"),
                              trailingIcon: Icon(Icons.video_call_rounded),
                              onPressed: () async {
                                await CustomProgressDialog.future(context,
                                    future: _flutterFFmpeg.execute(
                                      ' -start_number 1 -framerate 12 -i ${imageList[index]}/image_${name}_%4d.jpg -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,setsar=1" ${imageList[index]}/video.mp4 -r 24 -y',
                                    ),
                                    loadingWidget: Center(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SpinKitCubeGrid(
                                            color: AppTheme.appIndigo,
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              'Creating...',
                                              style: AppTheme.title,
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                    backgroundColor:
                                        Colors.grey.withOpacity(.5),
                                    blur: 2.0,
                                    dismissable: false);
                              }),
                          FocusedMenuItem(
                              title: Text("Backup data"),
                              trailingIcon: Icon(Icons.cloud_upload_rounded),
                              onPressed: () async {
                                var imagesDir = new Directory(imageList[index]);
                                var imagePaths = imagesDir
                                    .listSync()
                                    .map((item) => item.path)
                                    .toList(growable: false);
                                if (imagePaths.isNotEmpty) {
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
                                for (var path in imagePaths) {
                                  await Backend.uploadFile(
                                      File(path), folderName);
                                }
                              })
                        ],
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
                                  transitionType: DialogTransitionType.Bubble);
                              if (result) {
                                // Adds current dir, then force to null to trigger loading animation. After deletion current directory is reloaded
                                subdirs.add(_photoDir);
                                delete(imageList[index]);
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
                            imageList[index].endsWith('.jpg') ||
                                    imageList[index].endsWith('.mp4')
                                ? {
                                    subdirs.add('photo'),
                                    Navigator.of(context)
                                        .push(MaterialPageRoute(
                                            builder: (context) => PhotoScreen(
                                                imageList, index, isLocal)))
                                        .then((value) {
                                      if (value == 'pop') {
                                        subdirs.removeLast();
                                      } else if (value == 'delete') {
                                        subdirs.removeLast();
                                        subdirs.add(_photoDir);
                                        delete(imageList[index]);
                                      }
                                    })
                                  }
                                : {
                                    subdirs.add(_photoDir),
                                    updateDir(imageList[index])
                                  }
                          },
                          child: imageList[index].endsWith('.jpg')
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.file(
                                    File(imageList[index]),
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : imageList[index].endsWith('.mp4')
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.file(
                                            index == imageList.length - 1
                                                ? File(imageList[index - 1])
                                                : File(imageList[index + 1]),
                                            fit: BoxFit.fill,
                                          ),
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
                                        ]),
                        ),
                      ),
                    );
                  },
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
                    _photoDir = null;
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
                        _photoDir = null;
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
                        labelConstraints:
                            BoxConstraints.tightFor(width: 80.0, height: 30.0),
                        backgroundColor: AppTheme.notWhite,
                        // TODO if free user is logged in and at limit, show some sort of message
                        // Make this tappable with popup message, then take user to checkout page
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
                                    title: Text("Download"),
                                    trailingIcon: Icon(Icons.download_rounded),
                                    onPressed: () async {
                                      Fluttertoast.showToast(
                                          msg: "Downloading...",
                                          toastLength: Toast.LENGTH_SHORT,
                                          gravity: ToastGravity.CENTER,
                                          timeInSecForIosWeb: 1,
                                          backgroundColor: AppTheme.notWhite,
                                          textColor: AppTheme.appIndigo,
                                          fontSize: 16.0);

                                      if (directory[index].endsWith('.jpg') ||
                                          directory[index].endsWith('.mp4')) {
                                        await ImageDownloader.downloadImage(
                                            results[directory[index]]);
                                      } else {
                                        List files = results[directory[index]]
                                            .values
                                            .toList();
                                        for (var file in files) {
                                          await ImageDownloader.downloadImage(
                                              file);
                                        }
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
                                        // Add current dir, then force to null to trigger loading animation. After deletion current directory is reloaded
                                        subdirs.add(_photoDir);
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
                                    directory[index].endsWith('.jpg') ||
                                            directory[index].endsWith('.mp4')
                                        ? {
                                            subdirs.add('photo'),
                                            Navigator.of(context)
                                                .push(MaterialPageRoute(
                                                    builder: (context) =>
                                                        PhotoScreen(results,
                                                            index, isLocal)))
                                                .then((value) {
                                              if (value == 'pop') {
                                                subdirs.removeLast();
                                              } else if (value == 'delete') {
                                                subdirs.removeLast();
                                                subdirs.add(_photoDir);
                                                delete(directory[index]);
                                              }
                                            })
                                          }
                                        : {
                                            subdirs.add(_photoDir),
                                            updateDir(directory[index])
                                          }
                                  },
                                  child: directory[index].endsWith('.jpg')
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          child: CachedNetworkImage(
                                              imageUrl:
                                                  results[directory[index]],
                                              fit: BoxFit.cover,
                                              progressIndicatorBuilder:
                                                  (context, url,
                                                          downloadProgress) =>
                                                      SizedBox(
                                                        height: 10,
                                                        width: 10,
                                                        child: Center(
                                                          child: CircularProgressIndicator(
                                                              value:
                                                                  downloadProgress
                                                                      .progress),
                                                        ),
                                                      )),
                                        )
                                      : directory[index].endsWith('.mp4')
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                              child: Stack(
                                                fit: StackFit.expand,
                                                children: [
                                                  Image.network(
                                                    results[directory[1]],
                                                    fit: BoxFit.cover,
                                                  ),
                                                  Center(
                                                    child: CircleAvatar(
                                                      backgroundColor: Colors
                                                          .white
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
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Text(
                                                      dateToString(
                                                          directory[index]),
                                                      style: AppTheme.body1,
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  )
                                                ]),
                                ),
                              ),
                            );
                          },
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
