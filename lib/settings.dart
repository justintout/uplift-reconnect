import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ble.dart';

/// User preferences, backed directly by [SharedPreferences]. Reads are cheap
/// and writes are fire-and-forget, so the setters just notify.
class Settings extends ChangeNotifier {
  Settings(this._prefs);

  static const _autoConnectKey = 'autoconnect-enabled';
  static const _unitsKey = 'height-units';
  static const _holdIntervalKey = 'hold-interval-ms';
  static const _lastDeskIdKey = 'last-desk-id';
  static const _lastDeskNameKey = 'last-desk-name';

  static const holdIntervalChoices = [200, 400, 600, 800, 1000];
  static const defaultHoldInterval = 1000;

  final SharedPreferences _prefs;

  /// Reconnect to the last desk seen when the app opens.
  bool get autoConnect => _prefs.getBool(_autoConnectKey) ?? true;
  set autoConnect(bool value) {
    _prefs.setBool(_autoConnectKey, value);
    notifyListeners();
  }

  HeightUnit get units =>
      HeightUnit.values[_prefs.getInt(_unitsKey) ?? HeightUnit.inches.index];
  set units(HeightUnit value) {
    _prefs.setInt(_unitsKey, value.index);
    notifyListeners();
  }

  /// How often a held up or down button re-sends its command. The desk keeps
  /// moving for a moment after the last command, so a shorter interval stops
  /// it sooner when the button is released.
  Duration get holdInterval => Duration(
    milliseconds: _prefs.getInt(_holdIntervalKey) ?? defaultHoldInterval,
  );
  set holdInterval(Duration value) {
    _prefs.setInt(_holdIntervalKey, value.inMilliseconds);
    notifyListeners();
  }

  String? get lastDeskId => _prefs.getString(_lastDeskIdKey);
  String? get lastDeskName => _prefs.getString(_lastDeskNameKey);

  Future<void> rememberDesk(Device device) async {
    await _prefs.setString(_lastDeskIdKey, device.id);
    await _prefs.setString(_lastDeskNameKey, device.name);
  }
}

/// Makes [Settings] available to the widget tree, rebuilding readers when a
/// setting changes.
class SettingsScope extends InheritedNotifier<Settings> {
  const SettingsScope({
    super.key,
    required Settings settings,
    required super.child,
  }) : super(notifier: settings);

  static Settings of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<SettingsScope>();
    assert(scope != null, 'no SettingsScope above this widget');
    return scope!.notifier!;
  }
}
