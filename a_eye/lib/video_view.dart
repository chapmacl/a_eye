import 'package:a_eye/app_theme.dart';
import 'package:a_eye/string_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ndialog/ndialog.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

// ignore: must_be_immutable
class VideoScreen extends StatefulWidget {
  var video;
  bool isLocal;

  VideoScreen(this.video, this.isLocal);
  @override
  _VideoScreenState createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen>
    with TickerProviderStateMixin {
  Animation<double> _myAnimation;
  AnimationController _animController;
  VideoPlayerController _controller;
  String video_url;
  bool isLocal;

  @override
  void initState() {
    _animController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    _myAnimation =
        CurvedAnimation(curve: Curves.linear, parent: _animController);

    isLocal = widget.isLocal;
    video_url = widget.video;
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
    _controller = VideoPlayerController.network(video_url);
    Future _initializeVideoPlayerFuture = _controller.initialize();
    name = isLocal ? video_url.split('/').last : video_url;
    return Scaffold(
        appBar: AppBar(
          toolbarHeight: AppBar().preferredSize.height * 0.8,
          backgroundColor: Colors.black,
          leading: IconButton(
            icon:
                Icon(Icons.arrow_back_ios_rounded, color: AppTheme.nearlyWhite),
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
                        var text = dateToString(name);
                        Share.shareFiles([video_url], text: text);
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
                    ).show(context,
                        transitionType: DialogTransitionType.Bubble);
                    if (result) {
                      Navigator.pop(context, 'delete');
                    }
                  }),
            )
          ],
        ),
        body: FutureBuilder(
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
                        padding: const EdgeInsets.only(bottom: 10.0),
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
  }
}
