import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ble.dart';
import '../const.dart';

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class AutoconnectingHero extends StatelessWidget {
  const AutoconnectingHero({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: 5,
      child: Container(
        constraints: BoxConstraints(minWidth: double.infinity),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(32.0), color: Theme.of(context).primaryColor),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Text("Autoconnecting...", style: Theme.of(context).textTheme.headline2)],
        )
      )
    );
  }
}

class ControlButtonBar extends StatefulWidget {
  ControlButtonBar({Key key}) : super(key: key);

  @override
  _ControlButtonBarState createState() => _ControlButtonBarState();
}

class _ControlButtonBarState extends State<ControlButtonBar> {
  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: 3,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32.0),
          color: Theme.of(context).primaryColor
        ),
        child: Consumer2<Device, SharedPreferences>(
          builder: (context, device, preferences, _) {
            var enabled = device != null && device.ready;
            return ButtonBar(
            alignment: MainAxisAlignment.spaceAround,
            children: [
              ControlButton(
                icon: Icon(Icons.arrow_upward, size: 52.0, color: Theme.of(context).primaryColor), 
                held: true, 
                enabled:  enabled,
                command: enabled ? device.up : () => debugPrint("up but button not enabled"),
              ),
              ControlButton(
                icon: Icon(Icons.arrow_downward, size: 52.0, color: Theme.of(context).primaryColor), 
                held: true, 
                enabled:  enabled,
                command: enabled ? device.down : () => debugPrint("down but button not enabled")
              ),
              ControlButton(
                icon: Icon(Icons.accessibility, size: 52.0, color: Theme.of(context).primaryColor), 
                held: false, 
                enabled:  enabled ,
                command: enabled
                ? () {
                  try {
                    var height = preferences.getInt(PreferenceKey.STANDING_VALUE);
                    device.stand(height);
                  } catch (e) {
                    showDialog(context: context, builder: standNotSetAlert);
                  }
                } 
                : () => debugPrint("stand but button not enabled"),
                longPressCommand: () {
                  var height = device.height;
                  preferences.setInt(PreferenceKey.STANDING_VALUE, height.value)
                    .then((success) {
                      if (success) {
                        Scaffold.of(context).showSnackBar(
                          SnackBar(content: Text("Saved standing height: ${height.inches}\""),)
                        );
                      }
                    }).catchError((error) {
                      Scaffold.of(context).showSnackBar(
                          SnackBar(content: Text("Couldn't save standing height: ${error.toString()}"))
                      );
                    });
                },
              ),
              ControlButton(
                icon: Icon(Icons.airline_seat_legroom_normal, size: 52.0, color: Theme.of(context).primaryColor), 
                held: false, 
                enabled: enabled,
                command: enabled
                ? () {
                  try {
                    var height = preferences.getInt(PreferenceKey.SITTING_VALUE);
                    device.sit(height);
                  } catch (e) {
                    showDialog(context: context, builder: sitNotSetAlert);
                  }
                } 
                : () => debugPrint("stand but button not enabled"),
                longPressCommand: () {
                  var height = device.height;
                  preferences.setInt(PreferenceKey.SITTING_VALUE, height.value)
                    .then((success) {
                      if (success) {
                        Scaffold.of(context).showSnackBar(
                          SnackBar(content: Text("Saved sitting height: ${height.inches}\""))
                        );
                      }
                    }).catchError((error) {
                      Scaffold.of(context).showSnackBar(
                          SnackBar(content: Text("Couldn't save sitting height: ${error.toString()}"))
                      );
                    });
                }
              )
            ]
          );
        })
      )
    );  
  }
}

class _HomePageState extends State<HomePage> {

  static const appTitle = 'Uplift reConnect'; 
  
  Future<Device> _device;
  bool _isCheckingAutoconnect = true;
  bool _isAutoconnecting = false;

  // TODO: split to class, methods are antipattern
  Widget get _hero {
    var flex = 5;
    var constraints = BoxConstraints(minWidth: double.infinity);
    var decoration = BoxDecoration(borderRadius: BorderRadius.circular(32.0), color: Theme.of(context).primaryColor);
    return Consumer<Device>(
      builder: (context, device, _) {
        if (_isAutoconnecting) { 
          return AutoconnectingHero();
        }
        // before we have a device selected, show the "scan" hero
        if (device == null) {
          return Flexible(
            flex: flex,
            child: Container(
              constraints: constraints,
              decoration: decoration,
              child: InkWell(
                onTap: () async {
                  var scanResult = await Navigator.pushNamed(context, '/scan');
                  if (scanResult is ScanResult) {
                    setState(() {
                      _device = Future.value(Device(scanResult.device));
                      _device.then((device) => device.connect());
                    });
                  }
                },
                onLongPress: () async {
                  var devices = await FlutterBlue.instance.connectedDevices;
                  devices.forEach((device) => device.disconnect());
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Text("Tap to scan for desk", style: Theme.of(context).textTheme.headline2)]
                ),
              )
            )
          );
        }
        // once a device is selected, show the device info hero
        return Flexible(
            flex: flex,
            child: Container(
              constraints: constraints,
              decoration: decoration,
              child: Builder(
                builder: (context) {
                  switch(device.state) {
                    case BluetoothDeviceState.connecting:
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            Text(device.name, style: Theme.of(context).textTheme.headline1.apply(color: Theme.of(context).textTheme.headline1.color.withAlpha(60))),
                            Text(device.id.toString(), style: Theme.of(context).textTheme.headline2.apply(color: Theme.of(context).textTheme.headline2.color.withAlpha(60))),
                            Text("connecting...", style: Theme.of(context).textTheme.bodyText1)
                          ],
                      );
                    case BluetoothDeviceState.disconnecting:
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            Text(device.name, style: Theme.of(context).textTheme.headline1.apply(color: Theme.of(context).textTheme.headline1.color.withAlpha(60))),
                            Text(device.id.toString(), style: Theme.of(context).textTheme.headline2.apply(color: Theme.of(context).textTheme.headline2.color.withAlpha(60))),
                            Text("disconnecting...", style: Theme.of(context).textTheme.bodyText1)
                          ],
                      );
                    case BluetoothDeviceState.disconnected:
                      return InkWell(
                        onTap: () => device.connect(timeout: Duration(seconds: 5), autoConnect: true),
                        onLongPress: () async {
                          var scanResult = await Navigator.pushNamed(context, '/scan');
                          if (scanResult is ScanResult) {
                            setState(() {
                              _device = Future.value(Device(scanResult.device));
                            });
                          }
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(device.name, style: Theme.of(context).textTheme.headline1.apply(color: Theme.of(context).textTheme.headline1.color.withAlpha(60))),
                            Text(device.id.toString(), style: Theme.of(context).textTheme.headline2.apply(color: Theme.of(context).textTheme.headline2.color.withAlpha(60))),
                            Text("disconnected.", style: Theme.of(context).textTheme.bodyText1),
                            Text("tap to reconnect.", style: Theme.of(context).textTheme.bodyText1),
                            Text("long press to scan again.", style: Theme.of(context).textTheme.bodyText1)
                          ],
                        ),
                      );
                    case BluetoothDeviceState.connected:
                      return InkWell(
                        onTap: () => device.disconnect(),
                        onLongPress: () async {
                          var newName = await showDialog(
                            context: context,
                            builder: (context) {
                              final controller = TextEditingController(text: device.name);
                              return AlertDialog(
                                title: Row(
                                  children: [
                                    Icon(Icons.edit, color: Theme.of(context).accentColor),
                                    Text("Enter new desk name")
                                  ],
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    TextField(
                                      maxLength: 20,
                                      controller: controller,
                                      autofocus: true,
                                    )
                                  ],
                                ),
                                actions: [
                                  FlatButton(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
                                    color: Theme.of(context).accentColor,
                                    child: Text("Cancel", style: Theme.of(context).textTheme.button),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  FlatButton(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
                                    color: Theme.of(context).accentColor,
                                    child: Text("Save", style: Theme.of(context).textTheme.button),
                                    onPressed: () {
                                      var value = controller.value.text;
                                      Navigator.pop(context, value);
                                    }
                                  )
                                ],
                              );
                            }
                          );
                          if (newName != null && newName != device.name) {
                            debugPrint("new device name: $newName");
                            await device.rename(newName);
                          }
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(device.name, style: Theme.of(context).textTheme.headline1),
                            Text(device.id.toString(), style: Theme.of(context).textTheme.headline2),
                            Text("connected.", style: Theme.of(context).textTheme.bodyText1),
                            Text("tap to disconnect.", style: Theme.of(context).textTheme.bodyText1),
                            Text("long press to rename.", style: Theme.of(context).textTheme.bodyText1)
                          ],
                        )
                      );
                  }
                  assert(false, "this line should not be reached. not all cases for BluetoothDeviceState are covered");
                  return null;
              })
            )
        );
      },
    );
  }

  Widget get _spacer {
    return Flexible(
      flex: 1, 
      child: Consumer<Device>(
        builder: (context, device, _) {
          if (device == null) return Text(" ", style: Theme.of(context).textTheme.headline3);
          if (!device.ready || device.height == null) return Text("Device state: ${device.stateText}", style: Theme.of(context).textTheme.headline3);
          return Text("Height: ${device.height.inches}\"", style: Theme.of(context).textTheme.headline3);
        }
      )
    );
  }

  @override
  void initState() {
    super.initState();
    // check if there's a single desk device that autoconnected
    // if there is, use this device. 
    // TODO: I'd much rather use OUI to do this. Scanning for the service isn't nice.
    FlutterBlue.instance.connectedDevices.then((devices) {
      List<BluetoothDevice> upliftDevices = [];
      debugPrint("already connected to ${devices.length} ble device(s)");
      if (devices.length == 0) {
        setState((){
          _device = Future.value(null);
          _isCheckingAutoconnect = false;
        });
        return;
      }
      Future.wait(
        devices.map((device) => device.discoverServices().then((services) {
          debugPrint("services for ${device.id}: $services");
            if (services.indexWhere((service) => service.uuid == Guid(serviceUUID)) > -1) {
              upliftDevices.add(device);
              return;
            }
        }))
      ).then((_) {
        debugPrint("already connected to ${upliftDevices.length} desk(s)");
        if (upliftDevices.length == 1) {
          debugPrint("already connected to desk ${upliftDevices[0].id}");
          setState((){
            _device = Future.value(Device(upliftDevices[0]));
            _isCheckingAutoconnect = false;
            _isAutoconnecting = true;
          });
          _device
            .then((device) => device.discover())
            .then((_) => setState(() => _isAutoconnecting = false));
          return;
        }
        setState((){
          _device = Future.value(null);
          _isCheckingAutoconnect = false;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Device>(
      future: _device,
      initialData: null,
      builder: (context, snapshot) {
        if (snapshot.data == null && _isCheckingAutoconnect) {
          return Scaffold(
            backgroundColor: Theme.of(context).backgroundColor,
            appBar: AppBar(
              title: Text(appTitle)
            ),
            body: Padding(
              padding: EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(8.0)
                ),
                constraints: BoxConstraints.expand(width: double.infinity),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Initializing...", style: Theme.of(context).textTheme.headline1),
                    Text("One moment please.", style: Theme.of(context).textTheme.headline2)
                  ]
                )
              )
            )
          );
        }
        return MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: snapshot.data),
            FutureProvider.value(
              value: SharedPreferences.getInstance(),
              catchError: (_, error) {
                debugPrint("error getting prefs instance: ${error.toString()}");
              },
            )
          ],
          child: Scaffold(
            backgroundColor: Theme.of(context).backgroundColor,
            appBar: AppBar(
              title: Text(appTitle),
              actions: <Widget>[
                IconButton(icon: Icon(Icons.settings), onPressed: () => Navigator.pushNamed(context, '/settings'))
              ], 
            ),
            body: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                child: Flex(
                  direction: Axis.vertical,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [_hero, _spacer, ControlButtonBar()]
                )
              )
            )
          )
        );
      }
    );
  }
}

class ControlButton extends StatefulWidget {
  ControlButton({Key key, this.icon, this.command, this.held, this.enabled, this.longPressCommand}) : super(key: key);

  final Icon icon;
  final void Function() command;
  final void Function() longPressCommand;
  final bool held;
  final bool enabled;

  @override
  _ControlButtonState createState() => _ControlButtonState();
}

class _ControlButtonState extends State<ControlButton> {

  Timer _timer;

  _start() {
    _timer = Timer.periodic(Duration(milliseconds: 100), (timer) => timer.tick % 10 == 1 ? widget.command() : null);
  }

  _stop() {
    _timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return widget.held 
    ? Container(
       child: GestureDetector(
         onLongPressStart: (details) => _start(),
         onLongPressEnd: (details) => _stop(),
         child: ButtonTheme(
           height: 150.0,
           buttonColor: Theme.of(context).accentColor,
           disabledColor: Theme.of(context).accentColor.withAlpha(30),
           shape: CircleBorder(),
           child: RaisedButton(
            child: widget.icon,
            color: Theme.of(context).accentColor,
            onPressed: widget.enabled ? () => {} : null, 
            elevation: 8.0,
           ),
         ),
       ),
    )
    : ButtonTheme(
      height: 500.0,
      buttonColor: Theme.of(context).accentColor,
      disabledColor: Theme.of(context).accentColor.withAlpha(30),
      shape: CircleBorder(),
      child: RaisedButton(
        child: widget.icon,
        color: Theme.of(context).accentColor,
        onPressed: widget.enabled ? () => widget.command() : null,
        onLongPress: widget.enabled ? () => widget.longPressCommand() : null,
        elevation: 8.0,
      )
    );
  }
}

AlertDialog Function(BuildContext) sitNotSetAlert = (context) => AlertDialog(
  title: Text("Sitting height not set"),
  content: Text("Raise or lower your desk to sitting height, then log press the 'Sit' button to save."),
  actions: [
    FlatButton(
      child: Text("Ok"),
      onPressed: () {
        Navigator.pop(context);
      }
    )
  ]
);

AlertDialog Function(BuildContext) standNotSetAlert = (context) => AlertDialog(
  title: Text("Standing height not set"),
  content: Text("Raise or lower your desk to standing height, then log press the 'Stand' button to save."),
  actions: [
    FlatButton(
      child: Text("Ok"),
      onPressed: () {
        Navigator.pop(context);
      }
    )
  ]
);