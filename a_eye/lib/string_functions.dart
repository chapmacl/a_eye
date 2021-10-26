import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';

NumberFormat formatNum = new NumberFormat("00");

String dateToString(String filename) {
  bool timeUS = Settings.getValue('time', true);
  bool dateUS = Settings.getValue('date', true);
  String prettyPrint;
  String timePrint;
  String datePrint;
  if (filename.startsWith('image')) {
    // instance of Image: image_yyyy-mm-dd_HH:mm_0000.jpg
    List path = filename.split('_');
    path.removeAt(0);
    String img = path.last;
    path.removeLast();
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
        } else if (time.first == 24 || time.first == 0) {
          timePrint = '12:${time.last} a.m.';
        } else {
          timePrint = '${time.first % 12}:${time.last} p.m.';
        }
      } else {
        timePrint = '${time.first}:${time.last} a.m.';
      }
    } else {
      timePrint = '${formatNum.format(time.first)}:${time.last}';
    }
    prettyPrint = '$img from $timePrint $datePrint';
  } else if (filename.contains('video')) {
    prettyPrint = 'Video';
  } else {
    // instance of Folder: yyyy-mm-dd_HH:mm
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

String getTitle(String _photoDir) {
  String title;
  if (_photoDir == null) {
    title = '';
  } else if (_photoDir.endsWith('Shots')) {
    title = 'Internal Storage';
  } else if (_photoDir.contains('/')) {
    title = dateToString(_photoDir.split('/').last);
  } else if (_photoDir.endsWith('cloud')) {
    title = 'Cloud Storage';
  } else {
    title = '';
  }
  return title;
}
