import 'dart:io';
import 'package:a_eye/app_theme.dart';
import 'package:a_eye/string_functions.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ndialog/ndialog.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

// ignore: must_be_immutable
class PhotoScreen extends StatefulWidget {
  var imageList;
  int index;
  bool isLocal;

  PhotoScreen(this.imageList, this.index, this.isLocal);
  @override
  _PhotoScreenState createState() => _PhotoScreenState();
}

class _PhotoScreenState extends State<PhotoScreen>
    with TickerProviderStateMixin {
  Animation<double> _myAnimation;
  AnimationController _animController;
  VideoPlayerController _controller;
  List imageList;
  int index;
  bool isLocal;
  Map urls;

  @override
  void initState() {
    _animController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    _myAnimation =
        CurvedAnimation(curve: Curves.linear, parent: _animController);
    if (widget.imageList is List) {
      imageList = widget.imageList;
    } else {
      imageList = widget.imageList.keys.toList();
      imageList.sort((a, b) => b.toString().compareTo(a.toString()));
      urls = widget.imageList;
    }
    index = widget.index;
    isLocal = widget.isLocal;
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _animController.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String name;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: AppBar().preferredSize.height * 0.8,
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: AppTheme.nearlyWhite),
          onPressed: () {
            Navigator.pop(context, 'pop');
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: isLocal
                ? IconButton(
                    icon: Icon(Icons.share),
                    onPressed: () {
                      name = isLocal
                          ? imageList[index].split('/').last
                          : imageList[index];
                      var text = dateToString(name);
                      Share.shareFiles([imageList[index]], text: text);
                    })
                : Container(),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
                icon: Icon(
                  Icons.delete,
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
                  ).show(context, transitionType: DialogTransitionType.Bubble);
                  if (result) {
                    Navigator.pop(context, 'delete');
                  }
                }),
          )
        ],
      ),
      body: PhotoViewGallery.builder(
        scrollPhysics: const BouncingScrollPhysics(),
        builder: (BuildContext context, int index) {
          // It's almost guaranteed to only have 1 video, so find it in init and intialize there...
          isLocal
              ? _controller = VideoPlayerController.file(File(imageList[index]))
              : _controller =
                  VideoPlayerController.network(urls[imageList[index]]);
          Future _initializeVideoPlayerFuture = _controller.initialize();
          name = isLocal ? imageList[index].split('/').last : imageList[index];

          return PhotoViewGalleryPageOptions.customChild(
              minScale: PhotoViewComputedScale.contained * 1.0,
              initialScale: PhotoViewComputedScale.contained * 1.0,
              child: name.endsWith('jpg')
                  ? Container(
                      color: AppTheme.nearlyBlack,
                      child: Image(
                          image: isLocal
                              ? FileImage(File(imageList[index]))
                              : CachedNetworkImageProvider(
                                  urls[imageList[index]])))
                  : FutureBuilder(
                      future: _initializeVideoPlayerFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          _controller.setLooping(true);
                          return GestureDetector(
                            onTap: () {
                              if (_controller.value.isPlaying) {
                                _controller.pause();
                                _animController.reverse();
                              } else {
                                _controller.play();
                                _animController.forward();
                              }
                            },
                            child: Container(
                              color: AppTheme.nearlyBlack,
                              child: Stack(
                                children: [
                                  Center(
                                    child: AspectRatio(
                                        aspectRatio: 16.0 / 9.0,
                                        child: VideoPlayer(_controller)),
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 10.0),
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: AnimatedIcon(
                                        icon: AnimatedIcons.play_pause,
                                        progress: _myAnimation,
                                        color: Colors.white,
                                        size: 50,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        } else {
                          return Center(child: CircularProgressIndicator());
                        }
                      },
                    ));
        },
        itemCount: imageList.length,
        loadingBuilder: (context, progress) => Center(
          child: Container(
            width: 50.0,
            height: 50.0,
            child: CircularProgressIndicator(),
          ),
        ),
        backgroundDecoration: const BoxDecoration(
          color: Colors.black,
        ),
        pageController: PageController(initialPage: index),
      ),
    );
  }
}
