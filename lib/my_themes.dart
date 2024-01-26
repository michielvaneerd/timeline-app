import 'package:flutter/material.dart';

ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    appBarTheme: AppBarTheme(
        backgroundColor: Color(0xff2364AA), foregroundColor: Colors.white),
    colorScheme: ColorScheme.fromSeed(seedColor: Color(0xff2364AA)).copyWith(
        surface: Color(0xfffffaeb),
        surfaceTint: Color(0xffeff8fc),
        tertiary: Color(0xffFEC601),
        error: Color(0xffEA7317),
        secondary: Color(0xff3DA5D9)));

ThemeData darkTheme = ThemeData(brightness: Brightness.dark);
