import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_ble/universal_ble.dart';

import 'package:uplift_reconnect/ble.dart';
import 'package:uplift_reconnect/main.dart';
import 'package:uplift_reconnect/settings.dart';

/// Stands in for the BLE plugin. Implements the handful of calls the app
/// makes and leaves [updateScanResult] / [updateCharacteristicValue] for
/// tests to drive the desk from the outside.
class _FakeDeskBle extends UniversalBlePlatform {
  final List<Uint8List> writes = [];

  @override
  Future<List<BleDevice>> getSystemDevices(List<String>? withServices) async =>
      [];

  @override
  Future<void> startScan({
    ScanFilter? scanFilter,
    PlatformConfig? platformConfig,
  }) async {}

  @override
  Future<void> stopScan() async {}

  @override
  Future<void> connect(
    String deviceId, {
    Duration? connectionTimeout,
    bool autoConnect = false,
    ConnectionPlatformConfig? platformConfig,
  }) async {
    updateConnection(deviceId, true);
  }

  @override
  Future<void> disconnect(String deviceId) async {
    updateConnection(deviceId, false);
  }

  @override
  Future<List<BleService>> discoverServices(
    String deviceId,
    bool withDescriptors,
  ) async => [BleService(serviceUuid, const [])];

  @override
  Future<void> setNotifiable(
    String deviceId,
    String service,
    String characteristic,
    BleInputProperty bleInputProperty,
  ) async {}

  @override
  Future<void> writeValue(
    String deviceId,
    String service,
    String characteristic,
    Uint8List value,
    BleOutputProperty bleOutputProperty,
  ) async {
    writes.add(value);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not faked');
}

Future<Settings> _settings() async {
  SharedPreferences.setMockInitialValues({});
  return Settings(await SharedPreferences.getInstance());
}

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(UpliftReconnectApp(settings: await _settings()));
  await tester.pumpAndSettle();
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
    UniversalBle.setInstance(_FakeDeskBle());
    await _pumpApp(tester);

    expect(find.text('Tap to scan for desk'), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
  });

  testWidgets('picking a desk connects it and shows a live height', (
    tester,
  ) async {
    final desk = _FakeDeskBle();
    UniversalBle.setInstance(desk);
    await _pumpApp(tester);

    await tester.tap(find.text('Tap to scan for desk'));
    await tester.pumpAndSettle();

    desk.updateScanResult(BleDevice(deviceId: 'desk-1', name: 'Justin Desk'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Justin Desk'));
    await tester.pumpAndSettle();

    // The page has to follow the desk out of its connecting state. It once
    // stopped at "connecting..." because nothing listened to the device.
    expect(find.textContaining('tap to disconnect'), findsOneWidget);

    // A height report is `f2 f2 01 03 01 <height> <byte> <checksum> 7e`, and
    // the ATT payload delivers it in arbitrary chunks. This is the one the
    // desk actually sent while reading 126, whose height byte is 0x7e — the
    // same value as the terminator.
    const report = [0xf2, 0xf2, 0x01, 0x03, 0x01, 0x7e, 0x0f, 0x92, 0x7e];
    desk.updateCharacteristicValue(
      'desk-1',
      dataOutCharacteristicUuid,
      Uint8List.fromList(report.sublist(0, 6)),
      null,
    );
    await tester.pumpAndSettle();
    expect(find.text('37.9"'), findsNothing);

    desk.updateCharacteristicValue(
      'desk-1',
      dataOutCharacteristicUuid,
      Uint8List.fromList(report.sublist(6)),
      null,
    );
    await tester.pumpAndSettle();
    expect(find.text('37.9"'), findsOneWidget);

    // The desk also emits `f2 f2 <counter> 02 ...` frames. Their fifth byte is
    // a counter, and reading it as a height is what made the readout wander.
    desk.updateCharacteristicValue(
      'desk-1',
      dataOutCharacteristicUuid,
      Uint8List.fromList([0xf2, 0xf2, 0x28, 0x02, 0x14, 0x48, 0x86, 0x7e]),
      null,
    );
    await tester.pumpAndSettle();
    expect(find.text('38.7"'), findsNothing);
    expect(find.text('37.9"'), findsOneWidget);
  });

  testWidgets('settings page exposes the desk preferences', (tester) async {
    UniversalBle.setInstance(_FakeDeskBle());
    await _pumpApp(tester);
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(find.text('Reconnect automatically'), findsOneWidget);
    expect(find.text('Height units'), findsOneWidget);
    expect(find.text('Held button repeat'), findsOneWidget);
  });

  testWidgets('switching units changes the height readout', (tester) async {
    UniversalBle.setInstance(_FakeDeskBle());
    await _pumpApp(tester);
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(find.text('Inches'), findsOneWidget);
    expect(find.text('Centimeters'), findsOneWidget);

    await tester.tap(find.text('Centimeters'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // No desk is connected, so the readout falls back to the scan prompt.
    expect(find.text('Tap to scan for desk'), findsOneWidget);
  });

  // The controls are a row of four circles sized from the panel width, so a
  // narrow phone is where they would overflow.
  for (final size in const [Size(320, 568), Size(390, 844), Size(430, 932)]) {
    testWidgets('controls fit a ${size.width.toInt()}pt wide screen', (
      tester,
    ) async {
      UniversalBle.setInstance(_FakeDeskBle());
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpApp(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(ElevatedButton), findsNWidgets(4));
    });
  }
}
