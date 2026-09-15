import 'dart:async';

import 'package:flutter/material.dart';
import 'package:universal_ble/universal_ble.dart';

import '../ble.dart';
import '../const.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Device? _device;
  bool _checkingForDesk = true;

  @override
  void initState() {
    super.initState();
    _adoptConnectedDesk();
  }

  // The dongle keeps a connection to the phone after the app closes, so on
  // launch look for a desk that is already connected and pick it up.
  Future<void> _adoptConnectedDesk() async {
    Device? desk;
    try {
      await ensureBlePermissions();
      final devices = await UniversalBle.getSystemDevices(
        withServices: [serviceUuid],
      );
      if (devices.length == 1) {
        desk = Device(id: devices.single.deviceId, name: devices.single.name);
      }
    } catch (error) {
      debugPrint('could not list connected desks: $error');
    }
    if (!mounted) return;
    setState(() {
      _device = desk;
      _checkingForDesk = false;
    });
    await desk?.connect();
  }

  Future<void> _scan() async {
    final result = await Navigator.pushNamed(context, '/scan');
    if (result is! BleDevice || !mounted) return;
    setState(() {
      _device = Device(id: result.deviceId, name: result.name);
    });
    await _device?.connect();
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
    if (_checkingForDesk) {
      return const _StartupScaffold();
    }
    final device = _device;
    if (device == null) {
      return _scaffold(context, null);
    }
    return ListenableBuilder(
      listenable: device,
      builder: (context, _) => _scaffold(context, device),
    );
  }

  Widget _scaffold(BuildContext context, Device? device) {
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
        padding: const EdgeInsets.all(8.0),
        child: Flex(
          direction: Axis.vertical,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Flexible(flex: 5, child: _hero(context, device)),
            Flexible(flex: 1, child: _statusLine(context, device)),
            Flexible(flex: 3, child: ControlButtonBar(device: device)),
          ],
        ),
      ),
    );
  }

  Widget _hero(BuildContext context, Device? device) {
    if (device == null) {
      return _Panel(
        child: _HeroContents(
          title: 'Tap to scan for desk',
          onTap: _scan,
          onLongPress: _disconnectAll,
        ),
      );
    }

    final contents = switch (device.state) {
      DeskState.connecting => _HeroContents(
        title: device.name,
        subtitle: device.id,
        caption: 'connecting...',
      ),
      DeskState.connected => _HeroContents(
        title: device.name,
        subtitle: device.id,
        caption: 'connected.\ntap to disconnect.\nlong press to rename.',
        onTap: device.disconnect,
        onLongPress: () => _rename(device),
      ),
      DeskState.disconnected => _HeroContents(
        title: device.name,
        subtitle: device.id,
        caption:
            'disconnected.\ntap to reconnect.\nlong press to scan again.',
        onTap: device.connect,
        onLongPress: _scan,
      ),
    };
    return _Panel(child: contents);
  }

  Widget _statusLine(BuildContext context, Device? device) {
    final style = Theme.of(context).textTheme.titleMedium;
    final height = device?.height;
    if (device == null || !device.ready || height == null) {
      return Text(device?.stateText ?? ' ', style: style);
    }
    return Text('Height: ${height.inchesString}', style: style);
  }
}

class _StartupScaffold extends StatelessWidget {
  const _StartupScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(appTitle)),
      body: const Padding(
        padding: EdgeInsets.all(8.0),
        child: _Panel(
          child: _HeroContents(
            title: 'Initializing...',
            subtitle: 'One moment please.',
          ),
        ),
      ),
    );
  }
}

/// The rounded indigo tile the hero and control bar sit on.
class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding});

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32.0),
        color: Theme.of(context).colorScheme.primary,
      ),
      child: child,
    );
  }
}

class _HeroContents extends StatelessWidget {
  const _HeroContents({
    required this.title,
    this.subtitle,
    this.caption,
    this.onTap,
    this.onLongPress,
  });

  final String title;
  final String? subtitle;
  final String? caption;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final subtitle = this.subtitle;
    final caption = this.caption;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(32.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: textTheme.displayMedium,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            if (caption != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  caption,
                  style: textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ControlButtonBar extends StatelessWidget {
  const ControlButtonBar({super.key, required this.device});

  final Device? device;

  @override
  Widget build(BuildContext context) {
    final device = this.device;
    final enabled = device?.ready ?? false;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Four circles across the panel, leaving room for the gaps.
        final diameter = (constraints.maxWidth / 4) - 16.0;
        return _Panel(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ControlButton(
                icon: Icons.arrow_upward,
                diameter: diameter,
                enabled: enabled,
                onHold: device?.up,
              ),
              _ControlButton(
                icon: Icons.arrow_downward,
                diameter: diameter,
                enabled: enabled,
                onHold: device?.down,
              ),
              _ControlButton(
                icon: Icons.accessibility,
                diameter: diameter,
                enabled: enabled,
                onPressed: device == null ? null : () => device.stand(),
                onLongPress: device == null
                    ? null
                    : () => _savePreset(context, device.saveStand, 'standing'),
              ),
              _ControlButton(
                icon: Icons.airline_seat_legroom_normal,
                diameter: diameter,
                enabled: enabled,
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
    this.onPressed,
    this.onLongPress,
    this.onHold,
  });

  final IconData icon;
  final double diameter;
  final bool enabled;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final VoidCallback? onHold;

  @override
  State<_ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<_ControlButton> {
  static const _holdInterval = Duration(milliseconds: 1000);

  Timer? _holdTimer;

  void _startHold() {
    widget.onHold?.call();
    _holdTimer = Timer.periodic(_holdInterval, (_) => widget.onHold?.call());
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
          disabledBackgroundColor: scheme.secondary.withValues(alpha: 0.12),
          disabledForegroundColor: scheme.secondary.withValues(alpha: 0.3),
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
