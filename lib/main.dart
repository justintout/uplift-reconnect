import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/home.dart';
import 'pages/scan.dart';
import 'pages/settings.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // SettingsProvider(),
        Provider.value(
          value: 6
        )
      ],
      child: MaterialApp(
        title: 'Uplift reConnect',
        theme: ThemeData(
          primaryColor: Colors.indigo[800],
          accentColor: Colors.grey[200],
          backgroundColor: Colors.grey[200],
          textTheme: TextTheme(
            headline1: TextStyle(fontWeight: FontWeight.w200, color: Colors.grey[200], fontSize: 48.0),
            headline2: TextStyle(fontWeight: FontWeight.w400, color: Colors.grey[200], fontSize: 36.0),
            headline3: TextStyle(color: Colors.indigo, fontSize: 18.0),
            headline5: TextStyle(color: Colors.grey[200]),
            bodyText1: TextStyle(color: Colors.grey[200], fontWeight: FontWeight.w300),
            bodyText2: TextStyle(color: Colors.grey[200], fontWeight: FontWeight.w300, fontSize: 18.0),
            subtitle1: TextStyle(color: Colors.grey[200], fontWeight: FontWeight.w600, fontSize: 20.0),
            subtitle2: TextStyle(color: Colors.grey[200], fontWeight: FontWeight.w300, fontSize: 18.0),
            caption: TextStyle(color: Colors.grey[200], fontWeight: FontWeight.w200, fontSize: 16.0),
            button: TextStyle(color: Colors.indigo)
          ),
          dialogBackgroundColor: Colors.indigo[800],
          scaffoldBackgroundColor: Colors.indigo[800],
          dialogTheme: DialogTheme(
            backgroundColor: Colors.indigo[800],
            titleTextStyle: TextStyle(color: Colors.grey[200]),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
          ),
          cursorColor: Colors.grey[200],
          inputDecorationTheme: InputDecorationTheme(
            labelStyle: TextStyle(
              color: Colors.grey[200],
            ),
            hintStyle: TextStyle(
              color: Colors.grey[200].withAlpha(60)
            ),
            counterStyle: TextStyle(
              color: Colors.grey[200]
            ),
          ),
          buttonTheme: ButtonThemeData(
            buttonColor: Colors.grey[200],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
          ),
          textSelectionHandleColor: Colors.indigoAccent
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => HomePage(),
          '/scan': (context) => ScanPage(),
          '/settings': (context) => SettingsPage(),
        },
      ),
    );
  }
}
