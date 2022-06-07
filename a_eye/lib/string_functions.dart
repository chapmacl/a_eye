import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';

NumberFormat formatNum = new NumberFormat("00");

String dateToString(String filename) {
  bool timeUS = Settings.getValue('time', defaultValue: true)!;
  bool dateUS = Settings.getValue('date', defaultValue: true)!;
  String prettyPrint;
  String timePrint;
  String datePrint;
  if (!filename.contains('_')) {
    List date = filename.split('-');
    if (dateUS) {
      prettyPrint = '${date[1]}/${date[2]}/${date[0]}';
    } else {
      prettyPrint = '${date[2]}/${date[1]}/${date[0]}';
    }
  } else {
    // instance of Video: yyyy-mm-dd_HH:mm
    List path = filename.split('_');
    List date = path.first.split('-');
    List time = path.last.split(':');
    time = time.map((e) => int.parse(e)).toList();
    if (dateUS) {
      datePrint = '${date[1]}/${date[2]}/${date[0]}';
    } else {
      datePrint = '${date[2]}/${date[1]}/${date[0]}';
    }
    if (timeUS) {
      if (time.first > 11) {
        if (time.first == 12) {
          timePrint = '12:${time.last} p.m.';
        } else if (time.first == 24) {
          timePrint = '12:${time.last} a.m.';
        } else {
          timePrint = '${time.first % 12}:${time.last} p.m.';
        }
      } else {
        timePrint = '${time.first}:${time.last} a.m.';
      }
    } else {
      timePrint =
          '${formatNum.format(time.first)}:${formatNum.format(time.last)}';
    }
    prettyPrint = '$timePrint $datePrint';
  }
  return prettyPrint;
}

String getTitle(String _videoDir) {
  String title;
  if (_videoDir == null) {
    title = '';
  } else if (_videoDir.endsWith('Shots')) {
    title = 'Internal Storage';
  } else if (_videoDir.contains('/')) {
    title = dateToString(_videoDir.split('/').last);
  } else if (_videoDir.endsWith('cloud')) {
    title = 'Cloud Storage';
  } else {
    title = '';
  }
  return title;
}
