import 'package:url_launcher/url_launcher.dart';

import 'app_update.dart';

Future<bool> openReleasePage(String? url) async {
  final page = githubReleasePage(url);
  try {
    return await launchUrl(
      Uri.parse(page),
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {
    return false;
  }
}
