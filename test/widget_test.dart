import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_ble/universal_ble.dart';

import 'package:uplift_reconnect/ble.dart';
import 'package:uplift_reconnect/main.dart';

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

void main() {
  test('height byte converts to inches using the desk reading', () {
    // Samples captured from a desk in the README.
    expect(const Height(31).inches, closeTo(28.4, 0.01));
    expect(const Height(51).inches, closeTo(30.4, 0.01));
    expect(const Height(111).inches, closeTo(36.4, 0.01));
    expect(const Height(151).inches, closeTo(40.4, 0.01));
    expect(const Height(31).inchesString, '28.4"');
  });

  testWidgets('app starts on the scan prompt when no desk is connected', (
    tester,
  ) async {
    UniversalBle.setInstance(_NoDesksPlatform());

    await tester.pumpWidget(const UpliftReconnectApp());
    await tester.pumpAndSettle();

    expect(find.text('Tap to scan for desk'), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
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

      await tester.pumpWidget(const UpliftReconnectApp());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ElevatedButton), findsNWidgets(4));
    });
  }
}
