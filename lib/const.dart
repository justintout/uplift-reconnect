import 'package:flutter/material.dart';

const appTitle = 'Uplift reConnect';
const appVersion = '1.2.0';
const repositoryUrl = 'https://github.com/justintout/uplift-reconnect';

/// The desk's panels are indigo tiles sitting on a light page.
const indigo = Color(0xff283593); // indigo 800
const offWhite = Color(0xffeeeeee); // grey 200

/// Recolours a style for text sitting on an indigo panel.
TextStyle onPanel(TextStyle? style) => style!.copyWith(color: offWhite);
