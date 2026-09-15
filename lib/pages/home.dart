import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:universal_ble/universal_ble.dart';

import '../ble.dart';
import '../const.dart';
import '../settings.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Device? _device;
  bool _looking = true;
  bool _looked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_looked) return;
    _looked = true;
    _lookForDesk(SettingsScope.of(context));
  }

  /// The dongle keeps its link to the phone after the app closes, so prefer a
  /// desk the OS already has connected. Failing that, fall back to the desk
  /// this app connected to last time, if the user wants that.
  ///
  /// The lookup deliberately passes no service filter. On Android, filtering
  /// by service makes the plugin connect to each device to read its services
  /// and then disconnect it, which tears down the link this method is about
  /// to make.
  Future<void> _lookForDesk(Settings settings) async {
    Device? desk;
    try {
      await ensureBlePermissions();
      final connected = await UniversalBle.getSystemDevices();
      final lastDeskId = settings.lastDeskId;
      // Only a device this app has connected to before is a safe guess. Other
      // things on the phone are GATT-connected too, and connecting to one to
      // find out what it is would just fail slowly.
      for (final device in connected) {
        if (device.deviceId == lastDeskId) {
          desk = Device(id: device.deviceId, name: device.name);
          break;
        }
      }
      // The desk is usually not held by the system at all, because the app is
      // what connects it, so fall back to connecting to the remembered id.
      if (desk == null && settings.autoConnect && lastDeskId != null) {
        desk = Device(id: lastDeskId, name: settings.lastDeskName);
      }
    } catch (error) {
      debugPrint('could not look up connected desks: $error');
    }

    if (!mounted) return;
    setState(() {
      _device = desk;
      _looking = false;
    });
    if (desk != null) {
      await _connect(desk, settings);
    }
  }

  Future<void> _connect(Device desk, Settings settings) async {
    await desk.connect();
    if (desk.ready) {
      await settings.rememberDesk(desk);
    }
  }

  Future<void> _scan(Settings settings) async {
    final result = await Navigator.pushNamed(context, '/scan');
    if (result is! BleDevice || !mounted) return;
    final desk = Device(id: result.deviceId, name: result.name);
    setState(() => _device = desk);
    await _connect(desk, settings);
  }

  Future<void> _disconnectAll() async {
    final devices = await UniversalBle.getSystemDevices(
      withServices: [serviceUuid],
    );
    for (final device in devices) {
      await UniversalBle.disconnect(device.deviceId);
    }
  }

  Future<void> _rename(Device device) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => _RenameDialog(currentName: device.name),
    );
    if (newName == null || newName.isEmpty || newName == device.name) return;
    await device.rename(newName);
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.of(context);
    final device = _device;
    if (device == null) {
      return _scaffold(context, null, settings);
    }
    // The desk reports connection and height changes on its own, so the page
    // has to rebuild whenever the device notifies, not only on setState.
    return ListenableBuilder(
      listenable: device,
      builder: (context, _) => _scaffold(context, device, settings),
    );
  }

  Widget _scaffold(BuildContext context, Device? device, Settings settings) {
    final height = device?.height;

    // Whichever panel has something to say takes the slack: the desk card
    // while there is no reading, the readout once there is one.
    final deviceCard = _deviceCard(context, device, settings);

    return Scaffold(
      appBar: AppBar(
        title: const Text(appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (height == null)
              Expanded(child: deviceCard)
            else ...[
              deviceCard,
              const SizedBox(height: 12.0),
              Expanded(child: _heightCard(context, height, settings.units)),
            ],
            const SizedBox(height: 12.0),
            ControlButtonBar(
              device: device,
              holdInterval: settings.holdInterval,
            ),
          ],
        ),
      ),
    );
  }

  Widget _deviceCard(BuildContext context, Device? device, Settings settings) {
    if (_looking) {
      return const _Card(
        child: _CardContents(title: 'Looking for your desk...'),
      );
    }
    if (device == null) {
      return _Card(
        child: _CardContents(
          title: 'Tap to scan for desk',
          caption: 'Make sure the desk dongle is plugged in.',
          onTap: () => _scan(settings),
          onLongPress: _disconnectAll,
        ),
      );
    }

    final contents = switch (device.state) {
      DeskState.connecting => _CardContents(
        title: device.name,
        caption: 'connecting...',
      ),
      DeskState.connected => _CardContents(
        title: device.name,
        caption: 'connected.\ntap to disconnect.\nlong press to rename.',
        onTap: device.disconnect,
        onLongPress: () => _rename(device),
      ),
      DeskState.disconnected => _CardContents(
        title: device.name,
        caption:
            'disconnected.\ntap to reconnect.\nlong press to scan again.',
        onTap: () => _connect(device, settings),
        onLongPress: () => _scan(settings),
      ),
    };
    return _Card(child: contents);
  }

  Widget _heightCard(BuildContext context, Height height, HeightUnit unit) {
    return _Card(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 24.0),
      child: Center(
        // Centimetres make the readout the widest thing on screen, so let it
        // shrink rather than overflow on a narrow phone.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            height.format(unit),
            style: onPanel(Theme.of(context).textTheme.displayLarge),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// The rounded indigo tile the desk's panels sit on. Built on [Material] so
/// taps on the desk card ripple on the tile itself.
class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding});

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.primary,
      borderRadius: BorderRadius.circular(32.0),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
    );
  }
}

class _CardContents extends StatelessWidget {
  const _CardContents({
    required this.title,
    this.caption,
    this.onTap,
    this.onLongPress,
  });

  final String title;
  final String? caption;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final caption = this.caption;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  style: onPanel(textTheme.displayMedium),
                  textAlign: TextAlign.center,
                ),
              ),
              if (caption != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    caption,
                    style: onPanel(textTheme.bodyLarge),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ControlButtonBar extends StatelessWidget {
  const ControlButtonBar({
    super.key,
    required this.device,
    required this.holdInterval,
  });

  final Device? device;
  final Duration holdInterval;

  @override
  Widget build(BuildContext context) {
    final device = this.device;
    final enabled = device?.ready ?? false;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Four circles across the panel, leaving room for the gaps. The very
        // first frame can arrive before the view has a width, which would make
        // this negative and blow up the SizedBox underneath.
        final diameter = math.max(0.0, (constraints.maxWidth / 4) - 20.0);
        return _Card(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ControlButton(
                icon: Icons.arrow_upward,
                diameter: diameter,
                enabled: enabled,
                holdInterval: holdInterval,
                onHold: device?.up,
              ),
              _ControlButton(
                icon: Icons.arrow_downward,
                diameter: diameter,
                enabled: enabled,
                holdInterval: holdInterval,
                onHold: device?.down,
              ),
              _ControlButton(
                icon: Icons.accessibility,
                diameter: diameter,
                enabled: enabled,
                holdInterval: holdInterval,
                onPressed: device == null ? null : () => device.stand(),
                onLongPress: device == null
                    ? null
                    : () => _savePreset(context, device.saveStand, 'standing'),
              ),
              _ControlButton(
                icon: Icons.airline_seat_legroom_normal,
                diameter: diameter,
                enabled: enabled,
                holdInterval: holdInterval,
                onPressed: device == null ? null : () => device.sit(),
                onLongPress: device == null
                    ? null
                    : () => _savePreset(context, device.saveSit, 'sitting'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _savePreset(
    BuildContext context,
    Future<void> Function() save,
    String position,
  ) async {
    await save();
    if (!context.mounted) return;
    // The desk stores the preset itself and sends no acknowledgement.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Desk saved its $position position.')),
    );
  }
}

/// A circular desk control. Buttons with [onHold] repeat while held, so the
/// desk keeps moving until the finger comes off.
class _ControlButton extends StatefulWidget {
  const _ControlButton({
    required this.icon,
    required this.diameter,
    required this.enabled,
    required this.holdInterval,
    this.onPressed,
    this.onLongPress,
    this.onHold,
  });

  final IconData icon;
  final double diameter;
  final bool enabled;
  final Duration holdInterval;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final VoidCallback? onHold;

  @override
  State<_ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<_ControlButton> {
  Timer? _holdTimer;

  void _startHold() {
    widget.onHold?.call();
    _holdTimer = Timer.periodic(
      widget.holdInterval,
      (_) => widget.onHold?.call(),
    );
  }

  void _stopHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
  }

  @override
  void dispose() {
    _stopHold();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final button = SizedBox(
      width: widget.diameter,
      height: widget.diameter,
      child: ElevatedButton(
        // A held button still needs a non-null callback to render as enabled.
        onPressed: widget.enabled ? (widget.onPressed ?? () {}) : null,
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: scheme.secondary,
          foregroundColor: scheme.primary,
          disabledBackgroundColor: scheme.secondary.withValues(alpha: 0.22),
          disabledForegroundColor: scheme.secondary.withValues(alpha: 0.5),
          elevation: 8.0,
          padding: EdgeInsets.zero,
        ),
        child: Icon(widget.icon, size: widget.diameter * 0.45),
      ),
    );

    final onLongPress = widget.onLongPress;
    if (widget.onHold == null && onLongPress == null) {
      return button;
    }

    return GestureDetector(
      onLongPressStart: widget.onHold == null || !widget.enabled
          ? null
          : (_) => _startHold(),
      onLongPressEnd: widget.onHold == null || !widget.enabled
          ? null
          : (_) => _stopHold(),
      onLongPressCancel: widget.onHold == null || !widget.enabled
          ? null
          : _stopHold,
      onLongPress: onLongPress == null || !widget.enabled ? null : onLongPress,
      child: button,
    );
  }
}

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.currentName});

  final String currentName;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _controller = TextEditingController(text: widget.currentName);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.edit, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 8.0),
          const Text('Enter new desk name'),
        ],
      ),
      content: TextField(
        maxLength: 20,
        controller: _controller,
        autofocus: true,
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
