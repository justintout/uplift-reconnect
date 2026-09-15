import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../ble.dart';
import '../const.dart';
import '../settings.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24.0),
        children: [
          const _SectionHeader('Connection'),
          SwitchListTile(
            title: const Text('Reconnect automatically'),
            subtitle: const Text(
              'Connect to the last desk used whenever the app opens.',
            ),
            value: settings.autoConnect,
            onChanged: (value) => settings.autoConnect = value,
          ),
          const _SectionHeader('Display'),
          const ListTile(
            title: Text('Height units'),
            subtitle: Text('How the desk reports its height.'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SegmentedButton<HeightUnit>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: HeightUnit.inches,
                  label: Text('Inches'),
                ),
                ButtonSegment(
                  value: HeightUnit.centimeters,
                  label: Text('Centimeters'),
                ),
              ],
              selected: {settings.units},
              onSelectionChanged: (selection) =>
                  settings.units = selection.first,
            ),
          ),
          const _SectionHeader('Controls'),
          const ListTile(
            title: Text('Held button repeat'),
            subtitle: Text(
              'How often the up and down buttons re-send while held. The desk '
              'keeps moving briefly after the last command, so a shorter '
              'interval stops it sooner when you let go.',
            ),
          ),
          _HoldIntervalSlider(settings: settings),
          const _SectionHeader('About'),
          const AboutInfo(),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: indigo),
      ),
    );
  }
}

class _HoldIntervalSlider extends StatelessWidget {
  const _HoldIntervalSlider({required this.settings});

  final Settings settings;

  @override
  Widget build(BuildContext context) {
    const choices = Settings.holdIntervalChoices;
    final index = _nearestChoice(settings.holdInterval);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Slider(
              value: index.toDouble(),
              max: (choices.length - 1).toDouble(),
              divisions: choices.length - 1,
              label: '${choices[index]} ms',
              onChanged: (value) => settings.holdInterval = Duration(
                milliseconds: choices[value.round()],
              ),
            ),
          ),
          SizedBox(
            width: 88.0,
            child: Text(
              '${choices[index]} ms',
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }

  /// A stored interval written by an older build may not be one of the
  /// choices, so snap to the closest one the slider can show.
  int _nearestChoice(Duration current) {
    var best = 0;
    var bestDelta =
        (Settings.holdIntervalChoices.first - current.inMilliseconds).abs();
    for (var i = 1; i < Settings.holdIntervalChoices.length; i++) {
      final delta =
          (Settings.holdIntervalChoices[i] - current.inMilliseconds).abs();
      if (delta < bestDelta) {
        best = i;
        bestDelta = delta;
      }
    }
    return best;
  }
}

class AboutInfo extends StatelessWidget {
  const AboutInfo({super.key});

  void _openRepository() {
    launchUrl(Uri.parse(repositoryUrl), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: FaIcon(
        FontAwesomeIcons.github,
        size: 28.0,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: const Text('Source'),
      subtitle: const Text('justintout/uplift-reconnect'),
      onTap: _openRepository,
      trailing: TextButton(
        onPressed: () => showLicensePage(
          context: context,
          applicationName: appTitle,
          applicationVersion: appVersion,
        ),
        child: const Text('Licenses'),
      ),
    );
  }
}
