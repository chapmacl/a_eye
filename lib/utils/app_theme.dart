import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color notWhite = Color(0xFFEDF0F2);
  static const Color nearlyWhite = Color(0xFFFEFEFE);
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF2F3F8);
  static const Color nearlyBlack = Color(0xFF213333);
  static const Color grey = Color(0xFF3A5160);
  static const Color dark_grey = Color(0xFF313A44);

  static const Color pastelRed = Color(0xFFFF9AA2);
  static const Color pastelRose = Color(0xFFfeb8c6);
  static const Color pastelPink = Color(0xFFFFB7B2);
  static const Color pastelPeach = Color(0xFFFFDAC1);
  static const Color pastelYellow = Color(0xFFE2F0CB);
  static const Color pastelGreen = Color(0xFFB5EAD7);
  static const Color pastelBlue = Color(0xFFadd8e6);
  static const Color pastelPurple = Color(0xFFC7CEEA);

  static const Color appIndigo = Color(0xFF004e64);
  static const Color appBlue = Color(0xFF00a5cf);
  static const Color appCyan = Color(0xFF9fffcb);
  static const Color appDarkGreen = Color(0xFF25a18e);
  static const Color appGreen = Color(0xFF7ae582);

  static const Color nearlyDarkRed = Color(0xFFcc0000);
  static const Color nearlyBlue = Color(0xFF00B6F0);
  static const Color nearlyDarkBlue = Color(0xFF2633C5);
  static const Color darkText = Color(0xFF253840);
  static const Color darkerText = Color(0xFF17262A);
  static const Color lightText = Color(0xFF4A6572);
  static const Color deactivatedText = Color(0xFF767676);
  static const Color dismissibleBackground = Color(0xFF364A54);
  static const Color chipBackground = Color(0xFFEEF1F3);
  static const Color spacer = Color(0xFFF2F2F2);
  static const String fontName = 'Monsterrat';

  static const TextTheme textTheme = TextTheme(
    headline4: display1,
    headline5: headline,
    headline6: title,
    subtitle2: subtitle,
    bodyText2: body2,
    bodyText1: body1,
    caption: caption,
  );

  static const TextStyle display1 = TextStyle(
    // h4 -> display1
    fontFamily: fontName,
    fontWeight: FontWeight.bold,
    fontSize: 28,
    color: nearlyBlack,
    fontStyle: FontStyle.normal,
  );

  static const TextStyle logo = TextStyle(
    // h4 -> display1
    fontFamily: 'Monsterrat',
    fontWeight: FontWeight.w900,
    letterSpacing: 0.5,
    fontSize: 45,
    color: nearlyBlack,
    fontStyle: FontStyle.normal,
  );

  static const TextStyle headline = TextStyle(
    // h5 -> headline
    fontFamily: fontName,
    fontWeight: FontWeight.bold,
    fontSize: 25,
    color: darkerText,
    fontStyle: FontStyle.normal,
  );

  static const TextStyle title = TextStyle(
    // h6 -> title
    fontFamily: fontName,
    fontWeight: FontWeight.bold,
    fontSize: 20,
    letterSpacing: 0.18,
    color: appIndigo,
    fontStyle: FontStyle.normal,
  );

  static const TextStyle title2 = TextStyle(
    // h6 -> title
    fontFamily: fontName,
    fontWeight: FontWeight.w400,
    fontSize: 16,
    letterSpacing: 0.18,
    color: appIndigo,
    fontStyle: FontStyle.normal,
  );

  static const TextStyle title3 = TextStyle(
    // h6 -> title
    fontFamily: fontName,
    fontWeight: FontWeight.bold,
    fontSize: 18,
    letterSpacing: 0.18,
    color: lightText,
    fontStyle: FontStyle.normal,
  );

  static const TextStyle subtitle = TextStyle(
    // subtitle2 -> subtitle
    fontFamily: fontName,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    letterSpacing: -0.04,
    color: Colors.white,
    fontStyle: FontStyle.normal,
  );

  static const TextStyle subtitle2 = TextStyle(
    // subtitle2 -> subtitle
    fontFamily: fontName,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    letterSpacing: -0.04,
    color: appIndigo,
    fontStyle: FontStyle.normal,
  );

  static const TextStyle body2 = TextStyle(
    // body1 -> body2
    fontFamily: fontName,
    fontWeight: FontWeight.w400,
    fontSize: 16,
    letterSpacing: 0.2,
    color: Colors.white,
    fontStyle: FontStyle.normal,
  );

  static const TextStyle body1 = TextStyle(
    // body2 -> body1
    fontFamily: fontName,
    fontWeight: FontWeight.w400,
    fontSize: 16,
    letterSpacing: -0.05,
    color: darkText,
    fontStyle: FontStyle.normal,
  );

  static const TextStyle caption = TextStyle(
    // Caption -> caption
    fontFamily: fontName,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    letterSpacing: 0.2,
    color: darkText, // was lightText
    fontStyle: FontStyle.normal,
  );
}
