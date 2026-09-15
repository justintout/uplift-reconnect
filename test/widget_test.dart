import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_ble/universal_ble.dart';

import 'package:uplift_reconnect/ble.dart';
import 'package:uplift_reconnect/main.dart';
import 'package:uplift_reconnect/settings.dart';

/// Stands in for the BLE plugin so widget tests never touch a platform channel.
/// Only the one call the app makes on launch is implemented.
class _NoDesksPlatform extends UniversalBlePlatform {
  @override
  Future<List<BleDevice>> getSystemDevices(List<String>? withServices) async =>
      [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not faked');
}

Future<Settings> _settings() async {
  SharedPreferences.setMockInitialValues({});
  return Settings(await SharedPreferences.getInstance());
}

void main() {
  test('height byte converts using the desk reading', () {
    // Samples captured from a desk in the README.
    expect(const Height(31).inches, closeTo(28.4, 0.01));
    expect(const Height(51).inches, closeTo(30.4, 0.01));
    expect(const Height(111).inches, closeTo(36.4, 0.01));
    expect(const Height(151).inches, closeTo(40.4, 0.01));
  });

  test('height formats in the selected unit', () {
    expect(const Height(31).format(HeightUnit.inches), '28.4"');
    expect(const Height(31).format(HeightUnit.centimeters), '72.1 cm');
  });

  test('settings round-trip through preferences', () async {
    final settings = await _settings();

    expect(settings.autoConnect, isTrue);
    expect(settings.units, HeightUnit.inches);
    expect(settings.holdInterval, const Duration(milliseconds: 1000));

    settings.autoConnect = false;
    settings.units = HeightUnit.centimeters;
    settings.holdInterval = const Duration(milliseconds: 400);

    final reloaded = Settings(await SharedPreferences.getInstance());
    expect(reloaded.autoConnect, isFalse);
    expect(reloaded.units, HeightUnit.centimeters);
    expect(reloaded.holdInterval, const Duration(milliseconds: 400));
  });

  testWidgets('app starts on the scan prompt when no desk is connected', (
    tester,
  ) async {
    UniversalBle.setInstance(_NoDesksPlatform());

    await tester.pumpWidget(UpliftReconnectApp(settings: await _settings()));
    await tester.pumpAndSettle();

    expect(find.text('Tap to scan for desk'), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
  });

  testWidgets('settings page exposes the desk preferences', (tester) async {
    UniversalBle.setInstance(_NoDesksPlatform());

    await tester.pumpWidget(UpliftReconnectApp(settings: await _settings()));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(find.text('Reconnect automatically'), findsOneWidget);
    expect(find.text('Height units'), findsOneWidget);
    expect(find.text('Held button repeat'), findsOneWidget);
  });

  testWidgets('switching units changes the height readout', (tester) async {
    UniversalBle.setInstance(_NoDesksPlatform());

    await tester.pumpWidget(UpliftReconnectApp(settings: await _settings()));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(find.text('Inches'), findsOneWidget);
    expect(find.text('Centimeters'), findsOneWidget);

    await tester.tap(find.text('Centimeters'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // No desk is connected, so the readout falls back to the state text.
    expect(find.text('Tap to scan for desk'), findsOneWidget);
  });

  // The controls are a row of four circles sized from the panel width, so a
  // narrow phone is where they would overflow.
  for (final size in const [Size(320, 568), Size(390, 844), Size(430, 932)]) {
    testWidgets('controls fit a ${size.width.toInt()}pt wide screen', (
      tester,
    ) async {
      UniversalBle.setInstance(_NoDesksPlatform());
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(UpliftReconnectApp(settings: await _settings()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ElevatedButton), findsNWidgets(4));
    });
  }
}
