import 'dart:convert';

import 'package:a_eye/app_theme.dart';
import 'package:a_eye/backend.dart';
import 'package:a_eye/label_map.dart';
import 'package:a_eye/maps_screen.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:ndialog/ndialog.dart';

class SettingsArea extends StatefulWidget {
  @override
  _SettingsAreaState createState() => _SettingsAreaState();
}

class _SettingsAreaState extends State<SettingsArea> {
  String encodedMap = Settings.getValue('labelsmap', 'default');
  Map labelsMap;

  @override
  void initState() {
    super.initState();

    if (encodedMap == 'default') {
      labelsMap = getMap();
    } else {
      labelsMap = json.decode(encodedMap);
    }
  }

  @override
  Widget build(BuildContext context) {
    User user = Backend.getUser();
    bool result = false;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.notWhite,
        centerTitle: true,
        title: Text(
          'Settings',
          style: AppTheme.title,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SettingsContainer(
          allowScrollInternally: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                height: 50,
                child: ElevatedButton(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Image.asset(
                          'assets/images/google_logo.png',
                          height: 30,
                        ),
                        Flexible(
                          fit: FlexFit.tight,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: AutoSizeText(
                              user == null
                                  ? "Sign in with Google"
                                  : "Signed in as ${user.email}",
                              style: AppTheme.title3,
                              maxLines: 1,
                            ),
                          ),
                        ),
                        SizedBox()
                      ],
                    ),
                    style: ButtonStyle(
                        overlayColor: MaterialStateProperty.resolveWith(
                          (states) {
                            return states.contains(MaterialState.pressed)
                                ? Colors.black12
                                : null;
                          },
                        ),
                        foregroundColor: MaterialStateProperty.all<Color>(
                            AppTheme.nearlyBlack),
                        backgroundColor: MaterialStateProperty.all<Color>(
                            AppTheme.nearlyWhite),
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.0),
                        ))),
                    onPressed: () async {
                      user == null
                          ? await Backend.signInWithGoogle()
                          : result = await DialogBackground(
                              blur: 2.0,
                              dialog: AlertDialog(
                                title: Text("Sign Out?"),
                                actions: <Widget>[
                                  TextButton(
                                    child: Text("yes"),
                                    onPressed: () {
                                      Navigator.pop(context, true);
                                    },
                                  ),
                                  TextButton(
                                    child: Text("no"),
                                    onPressed: () {
                                      Navigator.pop(context, false);
                                    },
                                  )
                                ],
                              ),
                            ).show(context,
                              transitionType: DialogTransitionType.Bubble);
                      if (result) {
                        await Backend.signOut();

                        result = false;
                      }
                      setState(() {
                        user = Backend.getUser();
                      });
                    }),
              ),
            ),
            SwitchSettingsTile(
              defaultValue: true,
              settingKey: 'time',
              title: 'Time Format',
              enabledLabel: 'am/pm',
              disabledLabel: '24-hour',
              leading: Icon(Icons.access_time_rounded),
              onChange: (value) {
                setState(() {});
              },
            ),
            SwitchSettingsTile(
              defaultValue: true,
              settingKey: 'date',
              title: 'Date Format',
              enabledLabel: 'US (MM.DD.YYYY)',
              disabledLabel: 'European (DD.MM.YYYY)',
              leading: Icon(Icons.calendar_today),
              onChange: (value) {
                setState(() {});
              },
            ),
            SimpleSettingsTile(
              title: 'Object Detection',
              subtitle: 'Set which objects will be detected',
              leading: Icon(Icons.search),
              onTap: () async {
                Map result = await Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => MapScreen(labelsMap)));

                if (result != null && result == labelsMap) {
                  print('changed');
                  String encoded = json.encode(result);
                  await Settings.setValue('labelsmap', encoded);
                }
              },
            ),
            // TODO FUTURE more settings, color of boxes, maybe time settings for on/off, maybe flashlight when object is detected,
          ],
        ),
      ),
    );
  }
}
