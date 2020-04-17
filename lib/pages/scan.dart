import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:uplift_reconnect/ble.dart';

import '../ble.dart';


class ScanPage extends StatelessWidget {
  ScanPage({Key key}) : super(key: key);

  final message = "Select your desk from the list above. If it does not appear, make sure your " +
    "desk's BLE dongle is plugged in, stand closer to the desk, and try to scan again.";

  @override
  Widget build(BuildContext context) {
    FlutterBlue.instance.connectedDevices
      .then((devices) {
        devices.forEach((device) {
          device.discoverServices().then((services) {
            if (services.indexWhere((service) => service.uuid == Guid(serviceUUID)) > -1) {
              device.disconnect();
            }
          });
        });
      });
    FlutterBlue.instance.startScan(timeout: Duration(seconds: 30), withServices: [Guid(serviceUUID)]);
    return WillPopScope(
      onWillPop: () async {
        return FlutterBlue.instance.stopScan().then((_) => true);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Select your desk'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              FlutterBlue.instance.stopScan();
              Navigator.pop(context);
            },
          ),
        ),
        body: Center(
          child: ScanResults(message: message)
        ),
      ),
    );
  }
}

class ScanResults extends StatefulWidget {
  const ScanResults({
    Key key,
    @required this.message,
  }) : super(key: key);

  final String message;

  @override
  _ScanResultsState createState() => _ScanResultsState();
}

class _ScanResultsState extends State<ScanResults> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Flex(
        direction: Axis.vertical,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          Flexible(
            flex: 6,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).accentColor,
                borderRadius: BorderRadius.circular(32.0)
              ),
              child: StreamBuilder<List<ScanResult>>(
                stream: FlutterBlue.instance.scanResults,
                initialData: [],
                builder: (context, snapshot) => ListView(
                  children: snapshot.data.map((r) => ResultTile(result: r)).toList(),
                ),
              ),  
            )
          ),
          Flexible(
            flex: 2,
            child: Container(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(widget.message)
              ),
            )
          ),
          Flexible(
            flex: 2,
            child: ButtonBar(
              children: <Widget>[
                FlatButton(
                  color: Colors.grey[200],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
                  textColor: Theme.of(context).primaryColor,
                  child: Text('Cancel'),
                  onPressed: () {
                    FlutterBlue.instance.stopScan();
                    Navigator.pop(context);
                  } ,
                ),
                StreamBuilder(
                  initialData: true,
                  stream: FlutterBlue.instance.isScanning,
                  builder: (context, AsyncSnapshot<bool> snapshot) => FlatButton.icon(
                    icon: Icon(Icons.refresh),
                    color: Colors.grey[200],
                    disabledColor: Colors.grey[200].withAlpha(30),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
                    textColor: Theme.of(context).primaryColor,
                    label: snapshot.data ? Text('Scanning...') : Text('Restart scan'),
                    onPressed: snapshot.data ? null : () => FlutterBlue.instance.startScan(timeout: Duration(seconds: 30), withServices: [Guid(serviceUUID)] )
                  ),
                )
              ],
            )
          )
        ],            
      ) 
    );
  }
}

class ResultTile extends StatelessWidget {
  const ResultTile({Key key, @required ScanResult this.result}) : super(key: key);
  final ScanResult result;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
      color: Theme.of(context).primaryColor,
      child: ListTile(
        leading: Icon(Icons.bluetooth, size: 32, color: Theme.of(context).accentColor),
        title: Text(this.result.device.name),
        subtitle: Text(this.result.device.id.toString()),
        onTap: () {
          FlutterBlue.instance.stopScan();
          Navigator.pop(context, result);
        },
      ),
    );
  }
}