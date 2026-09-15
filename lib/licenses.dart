import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _asset = 'assets/native_licenses.json';

/// Adds the licences of the libraries the app ships natively. Flutter's own
/// NOTICES asset only covers the Dart packages, so the Android libraries Gradle
/// resolves and the pods CocoaPods installs are collected separately and merged
/// into the same page.
///
/// Regenerate [assets/native_licenses.json] with
/// `dart run tool/update_native_licenses.dart` after changing a dependency.
void registerNativeLicenses() {
  LicenseRegistry.addLicense(() async* {
    final entries =
        jsonDecode(await rootBundle.loadString(_asset)) as List<dynamic>;
    for (final entry in entries) {
      final licence = entry as Map<String, dynamic>;
      yield LicenseEntryWithLineBreaks(
        (licence['titles'] as List<dynamic>).cast<String>(),
        licence['text'] as String,
      );
    }
  });
}
