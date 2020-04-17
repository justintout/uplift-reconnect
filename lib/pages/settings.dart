import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uplift_reconnect/const.dart';
import 'package:url_launcher/url_launcher.dart';

import '../ble.dart';

Height _getHeight(SharedPreferences preferences, String key) {
  if (preferences == null || !preferences.containsKey(key)) {
    return null;
  }
  return Height(preferences.getInt(key));
}

class HeightInputDialog extends StatefulWidget {
  HeightInputDialog({Key key, @required this.prefKey, @required this.preferences}) : 
    assert(prefKey == PreferenceKey.STANDING_VALUE || prefKey == PreferenceKey.SITTING_VALUE),
    assert(preferences != null),
    super(key: key);

  final SharedPreferences preferences;
  // PreferenceKey prefKey;
  // TODO: use PreferenceKey and not string once extensions work
  final String prefKey;

  String get title {
    switch(prefKey) {
      case PreferenceKey.STANDING_VALUE:
        return "Set standing height";
      case PreferenceKey.SITTING_VALUE:
        return "Set sitting height";
    }
    return  "Set value";
  }

  // TODO: fix when prefKey changes
  String get hint => prefKey == PreferenceKey.STANDING_VALUE ? "40.6" : "28.4";

  @override
  _HeightInputDialogState createState() => _HeightInputDialogState();
}

class _HeightInputDialogState extends State<HeightInputDialog> {

  var _key = GlobalKey<FormState>();
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Container(
        child: Form(
          key: _key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  counterText: '',
                ),
                controller: TextEditingController.fromValue(TextEditingValue(text: widget.hint)),
                maxLength: 4,
                validator: (text) {
                  const error = "Height range: 24.3\" - 49.9\"";
                  var d = double.tryParse(text) ?? null;
                  if (d == null) return error;
                  return d <= 49.9 && d >= 24.3 ? null : error;
                },
                onSaved: (text) async {
                  var d = double.parse(double.parse(text).toStringAsPrecision(3));
                  var h = Height.fromInches(d);
                  try {
                    await widget.preferences.setInt(widget.prefKey, h.value);
                    Navigator.pop(context, h);
                  } catch (e) {
                    Navigator.pop(context, null);
                  }
                },
              ),
            ]
          ),
        )
      ),
      actions: [
        FlatButton(
          color: Colors.grey[200],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
          textColor: Theme.of(context).primaryColor,
          child: Text("Cancel"),
          onPressed: () => Navigator.pop(context),
        ),
        FlatButton(
          color: Colors.grey[200],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
          textColor: Theme.of(context).primaryColor,
          child: Text("Save"),
          onPressed: () async {
            if (_key.currentState.validate()) {
              _key.currentState.save();
            }
          },
        )
      ],
    );
  }
}

class StandingHeightSettingTile extends StatefulWidget {
  StandingHeightSettingTile({Key key, @required this.preferences}) : super(key: key);
  
  final SharedPreferences preferences;

  @override
  _StandingHeightSettingTileState createState() => _StandingHeightSettingTileState();
}

class _StandingHeightSettingTileState extends State<StandingHeightSettingTile> {

  Height _height;

  @override
  void initState() {
    _height = _getHeight(widget.preferences, PreferenceKey.STANDING_VALUE) ?? null;
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: _height != null,
      title: Text("Standing height"),
      subtitle: Text("Height, the desk will move to when the 'Stand' button is pressed."),
      isThreeLine: true,
      trailing: Text(_height?.inchesString ?? "Unset"),
      onTap: () async {
        var result = await showDialog<Height>(
          context: context, 
          builder: (context) => HeightInputDialog(preferences: widget.preferences, prefKey: PreferenceKey.STANDING_VALUE,)
        );
        if (result == null) {
          return;
        }
        if (result is Error) {
          Scaffold.of(context).showSnackBar(
            SnackBar(content: Text("Failed to save height: ${result.toString()}"))
          );
        }
        Scaffold.of(context).showSnackBar(
          SnackBar(content: Text("Saved height: ${result.inchesString}"))
        );
        setState(() {
          _height = result;
        });
      }
    );
  }
}

class SittingHeightSettingTile extends StatefulWidget {
  SittingHeightSettingTile({Key key, @required this.preferences}) : super(key: key);
  
  final SharedPreferences preferences;

  @override
  _SittingHeightSettingTileState createState() => _SittingHeightSettingTileState();
}

class _SittingHeightSettingTileState extends State<SittingHeightSettingTile> {

  Height _height;

  @override
  void initState() {
    _height = _getHeight(widget.preferences, PreferenceKey.SITTING_VALUE) ?? null;
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: _height != null,
      title: Text("Sitting height"),
      subtitle: Text("Height, the desk will move to when the 'Sit' button is pressed."),
      isThreeLine: true,
      trailing: Text(_height?.inchesString ?? "Unset"),
      onTap: () async {
        var result = await showDialog<Height>(
          context: context, 
          builder: (context) => HeightInputDialog(preferences: widget.preferences, prefKey: PreferenceKey.SITTING_VALUE,)
        );
        if (result == null) {
          return;
        }
        if (result is Error) {
          Scaffold.of(context).showSnackBar(
            SnackBar(content: Text("Failed to save height: ${result.toString()}"))
          );
        }
        Scaffold.of(context).showSnackBar(
          SnackBar(content: Text("Saved height: ${result.inchesString}"))
        );
        setState(() {
          _height = result;
        });
      }
    );
  }
}


class GeneralSettings extends StatefulWidget {
  const GeneralSettings({Key key}) : super(key: key);

  @override
  _GeneralSettingsState createState() => _GeneralSettingsState();
}

class _GeneralSettingsState extends State<GeneralSettings> {

  @override
  Widget build(BuildContext context) {
    return Consumer<SharedPreferences>(
        builder: (context, preferences, _) {
          if (preferences == null) {
            return Container(color: Colors.red);
          }
          return Container(
            child: ListView(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            children: [
              Text("General", style: Theme.of(context).textTheme.subtitle1),
              StandingHeightSettingTile(preferences: preferences),
              SittingHeightSettingTile(preferences: preferences),
            ],
          ),
        );
      }
    );
  }
}

class AccountSettings extends StatelessWidget {
  const AccountSettings({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => Container(
        child: ListView(
          shrinkWrap: true,
          children: [
            Text("Account", style: Theme.of(context).textTheme.subtitle1),
          ],
        )
      ),
    );
  }
}

class AboutInfo extends StatelessWidget {
  const AboutInfo({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => Container(
        child: ListView(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          children: [
            AboutListTile(
                applicationName: appTitle,
                applicationVersion: version,
                aboutBoxChildren: [RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.caption,
                    children: [
                      TextSpan(
                        text: summary
                      ),
                      TextSpan(
                        style: Theme.of(context).textTheme.caption,
                        text: '\n\nLearn more at '
                      ),
                      TextSpan(
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => launch('https://github.com/justintout/uplift-reconnect'),
                        text: 'github.com/jutintout/uplift-reconnect',
                        style: Theme.of(context).textTheme.caption.apply(decoration: TextDecoration.underline)
                      )
                    ]
                  )
                )],
              )
          ]
        )
      )
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key key}) : super(key: key);

  get _children {
    return [GeneralSettings(), AccountSettings(), AboutInfo()];
  }

  @override
  Widget build(BuildContext context) {
    return FutureProvider.value(
      initialData: null,
      value: SharedPreferences.getInstance(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Settings'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              constraints: BoxConstraints.expand(),
              child: ListTileTheme(
                style: ListTileStyle.list,
                contentPadding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                child: ListView.separated(
                  itemCount: 3,
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  itemBuilder: (context, i) => _children[i],
                  separatorBuilder: (_, __) => Divider(color: Theme.of(context).accentColor, height: 69.0),
                ),
              ),
            ),
          )
        ),
      ),
    );
  }
}