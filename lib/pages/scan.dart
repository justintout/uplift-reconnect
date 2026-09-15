import 'dart:async';

import 'package:flutter/material.dart';
import 'package:universal_ble/universal_ble.dart';

import '../ble.dart';
import '../const.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  static const _scanDuration = Duration(seconds: 30);
  static const _message =
      'Select your desk from the list above. If it does not appear, make sure '
      'your desk\'s BLE dongle is plugged in, stand closer to the desk, and try '
      'to scan again.';

  final _devices = <String, BleDevice>{};
  StreamSubscription<BleDevice>? _scanSubscription;
  Timer? _stopTimer;
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _scanSubscription = UniversalBle.scanStream.listen(_onScanResult);
    _startScan();
  }

  @override
  void dispose() {
    _stopTimer?.cancel();
    _scanSubscription?.cancel();
    UniversalBle.stopScan();
    super.dispose();
  }

  void _onScanResult(BleDevice device) {
    setState(() => _devices[device.deviceId] = device);
  }

  Future<void> _startScan() async {
    setState(() {
      _devices.clear();
      _scanning = true;
    });

    try {
      await ensureBlePermissions();
      // A desk that is already connected stops advertising, so drop any
      // existing link before looking for it again.
      final connected = await UniversalBle.getSystemDevices(
        withServices: [serviceUuid],
      );
      for (final device in connected) {
        await UniversalBle.disconnect(device.deviceId);
      }
      await UniversalBle.startScan(
        scanFilter: ScanFilter(withServices: [serviceUuid]),
      );
      _stopTimer?.cancel();
      _stopTimer = Timer(_scanDuration, _stopScan);
    } catch (error) {
      debugPrint('scan failed: $error');
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _stopScan() async {
    _stopTimer?.cancel();
    _stopTimer = null;
    await UniversalBle.stopScan();
    if (mounted) setState(() => _scanning = false);
  }

  void _select(BleDevice device) {
    UniversalBle.stopScan();
    Navigator.pop(context, device);
  }

  @override
  Widget build(BuildContext context) {
    final devices = _devices.values.toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select your desk'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Flex(
        direction: Axis.vertical,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Flexible(
            flex: 6,
            child: _ResultList(devices: devices, onSelect: _select),
          ),
          Flexible(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(_message, style: Theme.of(context).textTheme.bodyLarge),
            ),
          ),
          Flexible(
            flex: 2,
            child: Align(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16.0),
                  TextButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: Text(_scanning ? 'Scanning...' : 'Restart scan'),
                    onPressed: _scanning ? null : _startScan,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultList extends StatelessWidget {
  const _ResultList({required this.devices, required this.onSelect});

  final List<BleDevice> devices;
  final void Function(BleDevice) onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32.0),
        color: Theme.of(context).colorScheme.secondary,
      ),
      child: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          for (final device in devices)
            _ResultTile(device: device, onTap: () => onSelect(device)),
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.device, required this.onTap});

  final BleDevice device;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
      color: Theme.of(context).colorScheme.primary,
      child: ListTile(
        leading: Icon(
          Icons.bluetooth,
          size: 32,
          color: Theme.of(context).colorScheme.secondary,
        ),
        title: Text(device.name ?? 'Unnamed desk', style: onPanel(textTheme.bodyLarge)),
        subtitle: Text(device.deviceId, style: onPanel(textTheme.bodySmall)),
        onTap: onTap,
      ),
    );
  }
}
