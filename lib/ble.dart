import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue/flutter_blue.dart';

enum ConnectionState {
  CONNECTED, CONNECTING, DISCONNECTED, NO_DEVICE
}

const serviceUUID = '0000ff12-0000-1000-8000-00805f9b34fb';
const dataInCharacteristicUUID = '0000ff01-0000-1000-8000-00805f9b34fb';
const dataOutCharacteristicUUID = '0000ff02-0000-1000-8000-00805f9b34fb';
const nameCharacteristicUUID = '0000ff06-0000-1000-8000-00805f9b34fb';

const directionPacketDelay = 300; //ms
const deskQueryPacket = [0xf1, 0xf1, 0x07, 0x00, 0x07, 0x7e]; 
const deskUpPacket = [0xf1, 0xf1, 0x01, 0x00, 0x01, 0x7e];
const deskDownPacket = [0xf1, 0xf1, 0x02, 0x00, 0x02, 0x7e];
const heightNotificationDifference = 20; 
const defaultTimeout = Duration(seconds: 10);

// TODO: How does this actually work?
// Doing some estimation here: 
// https://www.upliftdesk.com/uplift-v2-standing-desk-v2-or-v2-commercial/
// Desk has a travel height of 25.6", from 24.3" - 49.9", so we can approximate to using the
// first value in the notification as the height.
// This value is the bottom of the legs, so add 1" for the desktop.
class Height {
  Height(this._value);
  static Height fromInches(double inches) {
    var value = (((inches - 1) * 10) - 243).toInt();
    return Height(value);
  }

  final int _value;
  
  int get value => _value;
  double get inches {
    return ((243 + _value) / 10) + 1;
  }
  double get percent {
    return (_value / 256) * 100;
  }
  String get inchesString => inches.toString() + "\"";
}

class Device with ChangeNotifier {
  Device(this._bluetoothDevice) {
    _name = _bluetoothDevice.name;
    _bluetoothDevice.state.listen((s) {
      state = s;
    });
  }

  BluetoothDevice _bluetoothDevice;
  BluetoothService _upliftService;
  BluetoothCharacteristic get _dataInCharacteristic => _upliftService == null ? throw "service not discovered" : _upliftService.characteristics.firstWhere((c) => c.uuid == Guid(dataInCharacteristicUUID));
  BluetoothCharacteristic get _dataOutCharacteristic => _upliftService == null ? throw "service not discovered" :  _upliftService.characteristics.firstWhere((c) => c.uuid == Guid(dataOutCharacteristicUUID));
  BluetoothCharacteristic get _nameCharacteristic => _upliftService == null ? throw "service not discovered" : _upliftService.characteristics.firstWhere((c) => c.uuid == Guid(nameCharacteristicUUID));
  StreamSubscription<List<int>> _listener;
  
  bool _connecting = false;

  String _stateText = "idle";
  String get stateText => _stateText;
  void set stateText(String text) {
    _stateText = text;
    notifyListeners();
  }

  BluetoothDeviceState _state = BluetoothDeviceState.disconnected;
  BluetoothDeviceState get state => _state;
  void set state(BluetoothDeviceState state) {
    debugPrint("state in from device: ${state}");
    if (_connecting) {
      _state = BluetoothDeviceState.connecting;
    } else {
      _state = state;
    }
    if (state == BluetoothDeviceState.disconnected) {
      stateText = "disconnected";
    }
    notifyListeners();
  }

  bool _ready = false;
  bool get ready => _ready;
  void set ready(bool r) {
    _ready = r;
    notifyListeners();
  }

  String _name;
  String get name => _name;
  void set name(String name) {
    _name = name;
    notifyListeners();
  }
  DeviceIdentifier get id => _bluetoothDevice.id;

  Height _height;
  Height get height => _height;
  void set height(Height h) {
    if (_height == null || h.value != _height.value) {
      _height = h;
      notifyListeners();
    }
  }
  
  Future<void> connect({timeout = const Duration(seconds: 5), autoConnect = false}) async {
    debugPrint("connecting to ${_bluetoothDevice.id}");
    stateText = "connecting";
    return  _bluetoothDevice.connect(timeout: timeout, autoConnect: autoConnect).timeout(timeout, onTimeout: () {
        stateText = "connection timed out";
        throw "connection timed out";
      })
      .then((_) => discover())
      .catchError((error) async {
        if (error is TimeoutException) {
          throw "uncaught timeoutException: ${error.toString()}";
        }
        if (error is PlatformException) {
          debugPrint("caught platformException: ${error.toString()}");
          if (error.code == "already_connected") {
            _connecting = false;
            return discover();
          }
        }
        throw "uncaught: ${error.toString()}";
      });
  }

  Future<void> discover() async {
    stateText = "discovering services";
    var services = await _bluetoothDevice.discoverServices();
    try {
      _upliftService = services.firstWhere((service) => service.uuid == Guid(serviceUUID));
      stateText = "subscribing to notifications";
      _connecting = false;
      await subscribe();
      await sendQuery();
      state = await _bluetoothDevice.state.first;
      ready = true;
      stateText = "connected";
      return;
    } catch (e) {
      debugPrint(e);
      stateText = "failed to connect";
      throw "failed to connect, couldn't find service";
    }
  }

  disconnect() {
    stateText = "disconnected";
    ready = false;
    unsubscribe();
    return _bluetoothDevice.disconnect();
  }

  subscribe() async {
    _listener = _dataOutCharacteristic.value.listen((notification){
      if (notification.length < 8) {
        return;
      }
      if (notification.first == 242 && notification.last != 126) {
        // first packet back from query. doesn't contain height;
        return;
      }
      if (notification.first != 242) {
        // second packet back from query
        height = Height(notification[17]);
        return;
      }
      height = Height(notification[5]);
    });
    await _dataOutCharacteristic.setNotifyValue(true);
  }

  unsubscribe() async {
    if (_listener != null) {
    _listener.cancel();
    }
    await _dataOutCharacteristic.setNotifyValue(false);
  }

  rename(String newName) async {
    var packet = utf8.encode(newName);
    debugPrint("new name packet: $packet");
    await _nameCharacteristic.write(utf8.encode(newName));
    await _updateName();
  }

  sendQuery() {
    debugPrint("send height query");
    _send(deskQueryPacket);
  }

  up() {
    debugPrint("up");
    _send(deskUpPacket);
  }

  down() {
    debugPrint("down");
    _send(deskDownPacket);
  }

  stand(int value) {
    debugPrint("stand, move ${value > height._value ? "up" : "down" } to $value");
    moveTo(value);
  }

  sit(int value) {
    debugPrint("sit, move ${value > height._value ? "up" : "down" } to $value");
    moveTo(value);
  }

  moveTo(int value) {
    var direction = _height.value > value ? "down" : "up";
    var timer = Timer.periodic(Duration(milliseconds: 1000), (_) {
      switch(direction) {
        case "up":
          return up();
        case "down":
          return down();
      }
    });
    // TODO: tune overshoot 
    var upOvershootCorrection = 13;
    var downOvershootCorrection = 18;
    this.addListener(() {
      if (direction == "down" ? height.value <= value + downOvershootCorrection : height.value >= value - upOvershootCorrection ) {
        timer.cancel();
      }
    });
  }

  _updateName() async {
    name = utf8.decode(await _nameCharacteristic.read());
  }

  _send(List<int> packet) async {
    await _dataInCharacteristic.write(packet);
  }
}
