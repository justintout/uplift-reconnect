import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../const.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Padding(
        padding: EdgeInsets.all(8.0),
        child: AboutInfo(),
      ),
    );
  }
}

class AboutInfo extends StatelessWidget {
  const AboutInfo({super.key});

  void _openRepository() {
    launchUrl(Uri.parse(repositoryUrl), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    return ListView(
      shrinkWrap: true,
      children: [
        AboutListTile(
          applicationName: appTitle,
          applicationVersion: appVersion,
          aboutBoxChildren: [
            RichText(
              text: TextSpan(
                style: style,
                children: [
                  const TextSpan(text: appSummary),
                  const TextSpan(text: '\n\nLearn more at '),
                  TextSpan(
                    text: repositoryUrl,
                    recognizer: TapGestureRecognizer()..onTap = _openRepository,
                    style: style?.copyWith(decoration: TextDecoration.underline),
                  ),
                ],
              ),
            ),
          ],
          child: const Text('About'),
        ),
      ],
    );
  }
}
