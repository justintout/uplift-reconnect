import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'const.dart';
import 'licenses.dart';
import 'pages/home.dart';
import 'pages/scan.dart';
import 'pages/settings.dart';
import 'settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerNativeLicenses();
  final settings = Settings(await SharedPreferences.getInstance());
  runApp(UpliftReconnectApp(settings: settings));
}

class UpliftReconnectApp extends StatelessWidget {
  const UpliftReconnectApp({super.key, required this.settings});

  final Settings settings;

  @override
  Widget build(BuildContext context) {
    return SettingsScope(
      settings: settings,
      child: MaterialApp(
        title: appTitle,
        theme: _theme,
        initialRoute: '/',
        routes: {
          '/': (context) => const HomePage(),
          '/scan': (context) => const ScanPage(),
          '/settings': (context) => const SettingsPage(),
        },
      ),
    );
  }
}

// The scheme is pinned rather than following the platform's light/dark setting,
// because the desk controls are indigo tiles on a light page.
final _theme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: indigo,
    brightness: Brightness.light,
  ).copyWith(
    primary: indigo,
    onPrimary: offWhite,
    secondary: offWhite,
    onSecondary: indigo,
    surface: offWhite,
    onSurface: indigo,
  ),
  scaffoldBackgroundColor: offWhite,
  appBarTheme: const AppBarTheme(
    backgroundColor: indigo,
    foregroundColor: offWhite,
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: indigo,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
  ),
  textSelectionTheme: const TextSelectionThemeData(
    cursorColor: offWhite,
    selectionHandleColor: Colors.indigoAccent,
  ),
  inputDecorationTheme: InputDecorationTheme(
    labelStyle: const TextStyle(color: offWhite),
    hintStyle: TextStyle(color: offWhite.withValues(alpha: 0.4)),
    counterStyle: const TextStyle(color: offWhite),
  ),
  // Colours are deliberately absent: most text sits either on an indigo panel
  // or on the light page, and the two need opposite treatments. Each call site
  // picks using [onPanel] or the default.
  textTheme: const TextTheme(
    displayLarge: TextStyle(fontWeight: FontWeight.w200, fontSize: 72),
    displayMedium: TextStyle(fontWeight: FontWeight.w400, fontSize: 32),
    titleLarge: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
    titleMedium: TextStyle(fontSize: 18),
    bodyLarge: TextStyle(fontWeight: FontWeight.w300),
    bodyMedium: TextStyle(fontWeight: FontWeight.w300, fontSize: 18),
    bodySmall: TextStyle(fontWeight: FontWeight.w200, fontSize: 16),
    labelLarge: TextStyle(fontWeight: FontWeight.w500),
  ),
);
