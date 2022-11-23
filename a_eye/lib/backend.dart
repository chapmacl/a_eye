import 'dart:io';
import 'package:a_eye/app_theme.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_settings_screens/flutter_settings_screens.dart'
    as settings;
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';

class Backend {
  static FirebaseAuth auth = FirebaseAuth.instance;
  static FirebaseStorage storage = FirebaseStorage.instance;
  static FirebaseFirestore firestore = FirebaseFirestore.instance;
  static GoogleSignIn googleSignIn = GoogleSignIn();
  static GoogleSignInAccount? googleSignInAccount;
  static User? user = auth.currentUser;

  static Future<FirebaseApp> initializeFirebase({
    BuildContext? context,
  }) async {
    FirebaseApp firebaseApp = await Firebase.initializeApp();
    if (user != null) {
      await googleSignIn.signInSilently().then((value) {
        print(value);
        googleSignInAccount = value;
      });
    }
    return firebaseApp;
  }

  static Future<User?> signInWithGoogle({BuildContext? context}) async {
    googleSignInAccount = await googleSignIn.signIn();

    if (googleSignInAccount != null) {
      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount!.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );

      try {
        final UserCredential userCredential =
            await auth.signInWithCredential(credential);

        user = userCredential.user;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'account-exists-with-different-credential') {
          Fluttertoast.showToast(
              msg: "The account already exists with a different credential",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: AppTheme.notWhite,
              textColor: AppTheme.appIndigo,
              fontSize: 16.0);
        } else if (e.code == 'invalid-credential') {
          Fluttertoast.showToast(
              msg: "Error occurred while accessing credentials. Try again.",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: AppTheme.notWhite,
              textColor: AppTheme.appIndigo,
              fontSize: 16.0);
        }
      } catch (e) {
        Fluttertoast.showToast(
            msg: "Error occurred using Google Sign In. Try again.",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: AppTheme.notWhite,
            textColor: AppTheme.appIndigo,
            fontSize: 16.0);
      }
    }
    if (user != null) updateFolderCount();
    return user;
  }

  static User? getUser() {
    return user;
  }

  static Future<void> signOut({BuildContext? context}) async {
    try {
      await auth.signOut();

      user = auth.currentUser;
      googleSignInAccount = null;
    } catch (e) {
      Fluttertoast.showToast(
          msg: "Error signing out. Try again.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: AppTheme.notWhite,
          textColor: AppTheme.appIndigo,
          fontSize: 16.0);
    }
  }

  static Future getFolders() async {
    QuerySnapshot q = await firestore
        .collection('users')
        .doc(user!.uid)
        .collection('captures')
        .get();
    Map results = {};
    q.docs.forEach((doc) {
      results[doc.id] = doc.get('urls');
    });
    return results;
  }

  // ignore: missing_return
  static Future makeMovie(
      String myImagePath, String myVideoPath, String subdir) async {
    var dir;
    if (subdir != null) {
      bool exists =
          await Directory('$myVideoPath/${subdir.split('_').first}').exists();
      if (!exists) {
        await new Directory('$myVideoPath/${subdir.split('_').first}')
            .create(recursive: true);
      }
      FFmpegKit.execute(
        ' -start_number 1 -framerate 12 -i $myImagePath/image_${subdir}_%4d.jpg -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,setsar=1" $myVideoPath/${subdir.split('_').first}/$subdir.mp4 -r 24 -y',
      ).then((value) async => {
            dir = new Directory(myImagePath),
            await dir.delete(recursive: true),
            if (settings.Settings.getValue('drive', defaultValue: false)!)
              {
                cloudSync('$myVideoPath/$subdir', subdir),
              }
          });
    }
  }

  static Future cloudSync(String myVideoPath, String subdir) async {
    await uploadFile(myVideoPath, subdir);
    if (settings.Settings.getValue('onlycloud', defaultValue: false)!) {
      var dir = new Directory(myVideoPath);
      await dir.delete(recursive: true);
    }
  }

  static Future getFiles(String dir) async {
    DocumentSnapshot q = await firestore
        .collection('users')
        .doc(user!.uid)
        .collection('captures')
        .doc(dir)
        .get();
    return q.get('urls');
  }

  static Future getUrlMap(String path) async {
    DocumentSnapshot q = await firestore
        .collection('users')
        .doc(user!.uid)
        .collection('captures')
        .doc(path.split('_').first)
        .get();
    return q.data();
  }

  static Future uploadFiles(List videoPaths, String subdir) async {
    Map urls = await getUrlMap(subdir);
    for (var video in videoPaths) {
      if (!urls['urls'].containsKey(video.split('/').last)) {
        await uploadFile(video, subdir);
      }
    }
  }

  static Future uploadFile(String videoPath, String subdir) async {
    String parent_dir = subdir.split('_').first;

    Reference ref = storage
        .ref()
        .child('${user!.uid}/${parent_dir}/${path.basename(videoPath)}');
    await ref.putFile(File(videoPath));
    var url = await ref.getDownloadURL();
    var video = firestore
        .collection('users')
        .doc(user!.uid)
        .collection('captures')
        .doc(parent_dir);
    await video.set({
      'urls': {path.basename(videoPath): url}
    }, SetOptions(merge: true));
    print('uploaded file ' + videoPath);
    updateFolderCount();
  }

  static Future deleteFile(var path) async {
    if (path.contains('.mp4')) {
      var parent = path.split('_').first;
      var video = await firestore
          .collection('users')
          .doc(user!.uid)
          .collection('captures')
          .doc(parent);
      var q = await video.get();
      var url = q.get('urls')[path];
      await storage.refFromURL(url).delete();
      Map updatedMap = q.get('urls');
      updatedMap.remove(path);
      await video.set({'urls': updatedMap});
    } else {
      var video = await firestore
          .collection('users')
          .doc(user!.uid)
          .collection('captures')
          .doc(path);
      var q = await video.get();
      var urls = q.get('urls').values.toList();
      for (var url in urls) {
        await storage.refFromURL(url).delete();
      }
      await video.delete();
    }
    updateFolderCount();
  }

  static Future updateFolderCount() async {
    //TODO if (user is not premium)... if the user is premium we don't care how many folder they have...
    //plus, this value can be updated at any time and only really matters to free users.

    // or an idea: premium user is -1 folders, so as to avoid more variables
    var folders = await getFolders();
    await settings.Settings.setValue('folders', folders.length);
  }
}

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;

  final http.Client _client = new http.Client();

  GoogleAuthClient(this._headers);

  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}
