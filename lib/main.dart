import 'package:flutter/material.dart';

import 'const.dart';
import 'pages/home.dart';
import 'pages/scan.dart';
import 'pages/settings.dart';

void main() => runApp(const UpliftReconnectApp());

const _indigo = Color(0xff283593); // indigo 800 — controls and app bar
const _offWhite = Color(0xffeeeeee); // grey 200 — the page and button fill

class UpliftReconnectApp extends StatelessWidget {
  const UpliftReconnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      theme: _theme,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/scan': (context) => const ScanPage(),
        '/settings': (context) => const SettingsPage(),
      },
    );
  }
}

// The desk controls read as a panel of indigo tiles on a light page, so the
// scheme is pinned rather than following the platform's light/dark setting.
final _theme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: _indigo,
    brightness: Brightness.light,
  ).copyWith(
    primary: _indigo,
    onPrimary: _offWhite,
    secondary: _offWhite,
    onSecondary: _indigo,
    surface: _offWhite,
    onSurface: _indigo,
  ),
  scaffoldBackgroundColor: _offWhite,
  appBarTheme: const AppBarTheme(
    backgroundColor: _indigo,
    foregroundColor: _offWhite,
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: _indigo,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
  ),
  textSelectionTheme: const TextSelectionThemeData(
    cursorColor: _offWhite,
    selectionHandleColor: Colors.indigoAccent,
  ),
  inputDecorationTheme: InputDecorationTheme(
    labelStyle: const TextStyle(color: _offWhite),
    hintStyle: TextStyle(color: _offWhite.withValues(alpha: 0.4)),
    counterStyle: const TextStyle(color: _offWhite),
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontWeight: FontWeight.w200,
      color: _offWhite,
      fontSize: 48,
    ),
    displayMedium: TextStyle(
      fontWeight: FontWeight.w400,
      color: _offWhite,
      fontSize: 36,
    ),
    titleLarge: TextStyle(
      color: _offWhite,
      fontWeight: FontWeight.w600,
      fontSize: 20,
    ),
    // Sits directly on the page, not on an indigo tile.
    titleMedium: TextStyle(color: _indigo, fontSize: 18),
    bodyLarge: TextStyle(color: _offWhite, fontWeight: FontWeight.w300),
    bodyMedium: TextStyle(
      color: _offWhite,
      fontWeight: FontWeight.w300,
      fontSize: 18,
    ),
    bodySmall: TextStyle(
      color: _offWhite,
      fontWeight: FontWeight.w200,
      fontSize: 16,
    ),
    labelLarge: TextStyle(color: _indigo),
  ),
);
