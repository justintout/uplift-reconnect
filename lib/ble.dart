import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:universal_ble/universal_ble.dart';

const serviceUuid = '0000ff12-0000-1000-8000-00805f9b34fb';
const dataInCharacteristicUuid = '0000ff01-0000-1000-8000-00805f9b34fb';
const dataOutCharacteristicUuid = '0000ff02-0000-1000-8000-00805f9b34fb';
const nameCharacteristicUuid = '0000ff06-0000-1000-8000-00805f9b34fb';

// Commands are `f1 f1 <command> 00 <command> 7e`: a fixed prefix, the command
// byte, a zero, the command repeated as a checksum, and a terminator. Captured
// from the Uplift Connect app; see the README for the full trace.
const _queryPacket = [0xf1, 0xf1, 0x07, 0x00, 0x07, 0x7e];
const _upPacket = [0xf1, 0xf1, 0x01, 0x00, 0x01, 0x7e];
const _downPacket = [0xf1, 0xf1, 0x02, 0x00, 0x02, 0x7e];
const _saveSitPacket = [0xf1, 0xf1, 0x03, 0x00, 0x03, 0x7e];
const _saveStandPacket = [0xf1, 0xf1, 0x04, 0x00, 0x04, 0x7e];
const _sitPacket = [0xf1, 0xf1, 0x05, 0x00, 0x05, 0x7e];
const _standPacket = [0xf1, 0xf1, 0x06, 0x00, 0x06, 0x7e];

const _connectionTimeout = Duration(seconds: 10);

/// Android 12 and up gate scanning and connecting behind runtime permissions,
/// and BLE silently does nothing without them. iOS and desktop hand these out
/// at the OS level, so there is nothing to request.
Future<bool> ensureBlePermissions() async {
  try {
    if (await UniversalBle.hasPermissions()) return true;
    await UniversalBle.requestPermissions();
    return true;
  } catch (error) {
    debugPrint('bluetooth permission denied: $error');
    return false;
  }
}

enum DeskState { connected, connecting, disconnected }

/// A height reported by the desk. The desk sends one byte where each unit is
/// roughly a tenth of an inch above the bottom of the legs, which put the
/// desktop 1" higher on the desk this was measured against.
class Height {
  const Height(this.value);

  final int value;

  double get inches => ((243 + value) / 10) + 1;
  double get centimeters => inches * 2.54;

  String format(HeightUnit unit) => switch (unit) {
    HeightUnit.inches => '${inches.toStringAsFixed(1)}"',
    HeightUnit.centimeters => '${centimeters.toStringAsFixed(1)} cm',
  };
}

/// The desk reports the same raw byte either way; this only changes how the
/// app writes it out.
enum HeightUnit { inches, centimeters }

/// A single desk. Wraps the BLE plumbing and exposes the desk's own controls.
class Device extends ChangeNotifier {
  Device({required this.id, String? name}) : _name = name ?? id {
    _connectionSubscription = UniversalBle.connectionStream(id).listen(
      _onConnectionChanged,
    );
  }

  final String id;

  String _name;
  String get name => _name;

  DeskState _state = DeskState.disconnected;
  DeskState get state => _state;

  String _stateText = 'idle';
  String get stateText => _stateText;

  Height? _height;
  Height? get height => _height;

  /// True once services are discovered and notifications are flowing, so the
  /// desk will accept commands.
  bool _ready = false;
  bool get ready => _ready;

  StreamSubscription<bool>? _connectionSubscription;
  StreamSubscription<Uint8List>? _valueSubscription;

  Future<void> connect() async {
    if (_state != DeskState.disconnected) {
      return;
    }
    _state = DeskState.connecting;
    _stateText = 'connecting';
    notifyListeners();

    try {
      await UniversalBle.connect(id, timeout: _connectionTimeout);
      await _discover();
    } catch (error) {
      _setDisconnected('failed to connect: $error');
      // Failing partway through discovery can leave the link up.
      try {
        await UniversalBle.disconnect(id);
      } catch (_) {
        // Nothing to tear down.
      }
    }
  }

  Future<void> disconnect() async {
    _setDisconnected('disconnected');
    await UniversalBle.disconnect(id);
  }

  Future<void> _discover() async {
    _stateText = 'discovering services';
    notifyListeners();

    final services = await UniversalBle.discoverServices(id);
    if (!services.any((service) => service.uuid == serviceUuid)) {
      throw StateError('no Uplift service on this device');
    }

    _stateText = 'subscribing to notifications';
    notifyListeners();
    await UniversalBle.subscribeNotifications(
      id,
      serviceUuid,
      dataOutCharacteristicUuid,
    );
    _valueSubscription = UniversalBle.characteristicValueStream(
      id,
      dataOutCharacteristicUuid,
    ).listen(_onNotification);

    _state = DeskState.connected;
    _stateText = 'connected';
    _ready = true;
    notifyListeners();

    await sendQuery();
  }

  void _onConnectionChanged(bool isConnected) {
    if (!isConnected) {
      _setDisconnected('disconnected');
    }
  }

  void _setDisconnected(String text) {
    _valueSubscription?.cancel();
    _valueSubscription = null;
    _ready = false;
    _state = DeskState.disconnected;
    _stateText = text;
    notifyListeners();
  }

  /// Three packet shapes arrive on data-out, all carrying the height byte in a
  /// different place. See the README for captured samples of each.
  void _onNotification(Uint8List notification) {
    // Unsolicited: the desk's own button pad moved it.
    if (notification.length == 3) {
      _setHeight(Height(notification[0]));
      return;
    }
    if (notification.length < 18) {
      return;
    }
    if (notification.first == 0xf2) {
      // First half of a query response. Carries no height, and is the only
      // packet that ends in something other than the 0x7e terminator.
      if (notification.last == 0x7e) {
        _setHeight(Height(notification[5]));
      }
      return;
    }
    // Second half of a query response.
    _setHeight(Height(notification[17]));
  }

  void _setHeight(Height height) {
    if (_height?.value == height.value) {
      return;
    }
    _height = height;
    notifyListeners();
  }

  Future<void> rename(String newName) async {
    await UniversalBle.write(
      id,
      serviceUuid,
      nameCharacteristicUuid,
      Uint8List.fromList(utf8.encode(newName)),
    );
    final written = await UniversalBle.read(
      id,
      serviceUuid,
      nameCharacteristicUuid,
    );
    _name = utf8.decode(written);
    notifyListeners();
  }

  Future<void> sendQuery() => _send(_queryPacket);
  Future<void> up() => _send(_upPacket);
  Future<void> down() => _send(_downPacket);

  /// Move to the height the desk has stored as its sitting preset.
  Future<void> sit() => _send(_sitPacket);

  /// Move to the height the desk has stored as its standing preset.
  Future<void> stand() => _send(_standPacket);

  /// Store the desk's current height as its sitting preset.
  Future<void> saveSit() => _send(_saveSitPacket);

  /// Store the desk's current height as its standing preset.
  Future<void> saveStand() => _send(_saveStandPacket);

  // Every desk command goes out on data-in, which is write-without-response.
  Future<void> _send(List<int> packet) => UniversalBle.write(
    id,
    serviceUuid,
    dataInCharacteristicUuid,
    Uint8List.fromList(packet),
    withoutResponse: true,
  );

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _valueSubscription?.cancel();
    super.dispose();
  }
}
