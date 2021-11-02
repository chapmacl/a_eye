import 'dart:io';
import 'package:a_eye/app_theme.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class Backend {
  static FirebaseAuth auth = FirebaseAuth.instance;
  static FirebaseStorage storage = FirebaseStorage.instance;
  static FirebaseFirestore firestore = FirebaseFirestore.instance;
  static GoogleSignIn googleSignIn = GoogleSignIn();
  static GoogleSignInAccount googleSignInAccount;
  static User user = auth.currentUser;

  // TODO remove
  // static SnackBar customSnackBar({String content}) {
  //   return SnackBar(
  //     backgroundColor: Colors.transparent,
  //     elevation: 0,
  //     content: Container(
  //         padding: const EdgeInsets.all(8),
  //         decoration: BoxDecoration(
  //           color: AppTheme.notWhite,
  //           border: Border.all(color: AppTheme.appIndigo, width: 1),
  //           boxShadow: const [
  //             BoxShadow(
  //               color: Color(0x19000000),
  //               spreadRadius: 2.0,
  //               blurRadius: 8.0,
  //               offset: Offset(2, 4),
  //             )
  //           ],
  //           borderRadius: BorderRadius.circular(4),
  //         ),
  //         child: Row(
  //           children: [
  //             Padding(
  //               padding: EdgeInsets.only(left: 8.0),
  //               child: Text(
  //                 content,
  //                 style: AppTheme.title,
  //                 textAlign: TextAlign.center,
  //               ),
  //             ),
  //           ],
  //         )),
  //   );
  // }

  static Future<FirebaseApp> initializeFirebase({
    BuildContext context,
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

  static Future<User> signInWithGoogle({BuildContext context}) async {
    googleSignInAccount = await googleSignIn.signIn();

    if (googleSignInAccount != null) {
      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;

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
    // TODO function to check for number of folders in firebase. If it is over the
    // threshold (eg. 5), disable cloud upload.
    return user;
  }

  static User getUser() {
    return user;
  }

  static Future<void> signOut({BuildContext context}) async {
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
        .doc(user.uid)
        .collection('photos')
        .get();
    Map results = {};
    q.docs.forEach((doc) {
      results[doc.id] = doc.get('urls');
    });
    return results;
  }

  static Future getFiles(String dir) async {
    DocumentSnapshot q = await firestore
        .collection('users')
        .doc(user.uid)
        .collection('photos')
        .doc(dir)
        .get();
    return q.get('urls');
  }

  // TODO where to use this?
  static Future doesFileExist(String path) async {
    DocumentSnapshot q = await firestore
        .collection('users')
        .doc(user.uid)
        .collection('photos')
        .doc(path)
        .get();
    return q.exists;
  }

  static Future uploadFile(File file, String parent_dir) async {
    Reference ref = storage.ref().child(
        '${user.uid}/${parent_dir}/${path.basename(file.absolute.path)}');
    await ref.putFile(file);
    var url = await ref.getDownloadURL();
    var photo = firestore
        .collection('users')
        .doc(user.uid)
        .collection('photos')
        .doc(parent_dir);
    await photo.set({
      'urls': {path.basename(file.absolute.path): url}
    }, SetOptions(merge: true));
    print('uploaded file ' + file.path);
  }

  static Future deleteFile(var path) async {
    if (path.contains('.jpg') || path.contains('.mp4')) {
      var parts = path.split('_');
      var parent = '${parts[1]}_${parts[2]}';
      var photo = await firestore
          .collection('users')
          .doc(user.uid)
          .collection('photos')
          .doc(parent);
      var q = await photo.get();
      var url = q.get('urls')[path];
      await storage.refFromURL(url).delete();
      Map updatedMap = q.get('urls');
      updatedMap.remove(path);
      await photo.set({'urls': updatedMap});
    } else {
      var photo = await firestore
          .collection('users')
          .doc(user.uid)
          .collection('photos')
          .doc(path);
      var q = await photo.get();
      var urls = q.get('urls').values.toList();
      for (var url in urls) {
        await storage.refFromURL(url).delete();
      }
      await photo.delete();
    }
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
