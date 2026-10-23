import 'dart:convert';

import 'package:http/http.dart' as http;

const developerName = 'Axcel Blade';
const githubUsername = 'axcel-blade';
const githubProfileUrl = 'https://github.com/axcel-blade';

const githubRepository = 'axcel-blade/HNB-Solo-Tracker';

const githubReleasesPage =
    'https://github.com/axcel-blade/HNB-Solo-Tracker/releases';

const updateAvailableTitle = 'A new version is available';
const upToDateMessage = 'You are using the latest version.';
const updateCheckFailedMessage =
    'Could not reach GitHub. Check the connection and try again.';

enum UpdateStatus { upToDate, available, unavailable }

class AppVersion implements Comparable<AppVersion> {
  const AppVersion(this.major, this.minor, this.patch);

  final int major;
  final int minor;
  final int patch;

  static final _pattern = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)');

  static AppVersion? parse(String raw) {
    final match = _pattern.firstMatch(raw.trim());
    if (match == null) return null;
    return AppVersion(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  bool isNewerThan(AppVersion other) => compareTo(other) > 0;

  @override
  int compareTo(AppVersion other) {
    final majorDiff = major.compareTo(other.major);
    if (majorDiff != 0) return majorDiff;
    final minorDiff = minor.compareTo(other.minor);
    if (minorDiff != 0) return minorDiff;
    return patch.compareTo(other.patch);
  }

  @override
  String toString() => '$major.$minor.$patch';
}

class UpdateResult {
  const UpdateResult._({
    required this.status,
    required this.currentVersion,
    required this.message,
    this.latestVersion,
    this.pageUrl,
    this.notes,
  });

  const UpdateResult.upToDate(String currentVersion)
    : this._(
        status: UpdateStatus.upToDate,
        currentVersion: currentVersion,
        message: '$upToDateMessage ($currentVersion)',
      );

  const UpdateResult.available({
    required String currentVersion,
    required String latestVersion,
    required String pageUrl,
    required String notes,
  }) : this._(
         status: UpdateStatus.available,
         currentVersion: currentVersion,
         message:
             'Version $latestVersion is available. You are using $currentVersion.',
         latestVersion: latestVersion,
         pageUrl: pageUrl,
         notes: notes,
       );

  const UpdateResult.unavailable(String currentVersion, String message)
    : this._(
        status: UpdateStatus.unavailable,
        currentVersion: currentVersion,
        message: message,
      );

  final UpdateStatus status;
  final String currentVersion;
  final String message;
  final String? latestVersion;
  final String? pageUrl;
  final String? notes;
}

abstract class UpdateChecker {
  String get currentVersion;

  Future<UpdateResult> check();
}

class DisabledUpdateChecker implements UpdateChecker {
  const DisabledUpdateChecker({this.currentVersion = '1.0.0'});

  @override
  final String currentVersion;

  @override
  Future<UpdateResult> check() async {
    return UpdateResult.unavailable(
      currentVersion,
      'Update checking is turned off.',
    );
  }
}

class GithubUpdateChecker implements UpdateChecker {
  GithubUpdateChecker({
    required this.currentVersion,
    this.client,
    this.repository = githubRepository,
  });

  @override
  final String currentVersion;

  final String repository;
  final http.Client? client;

  @override
  Future<UpdateResult> check() async {
    final current = AppVersion.parse(currentVersion);
    if (current == null) {
      return UpdateResult.unavailable(
        currentVersion,
        'This app version could not be read.',
      );
    }
    final httpClient = client ?? http.Client();
    final closeClient = client == null;
    try {
      final response = await httpClient
          .get(
            Uri.parse(
              'https://api.github.com/repos/$repository/releases/latest',
            ),
            headers: const {
              'Accept': 'application/vnd.github+json',
              'User-Agent': 'hnb-solo-tracker',
            },
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode == 404) {
        return UpdateResult.unavailable(
          currentVersion,
          'No GitHub release was found.',
        );
      }
      if (response.statusCode != 200) {
        return UpdateResult.unavailable(
          currentVersion,
          updateCheckFailedMessage,
        );
      }
      return _fromRelease(current, response.body);
    } catch (_) {
      return UpdateResult.unavailable(currentVersion, updateCheckFailedMessage);
    } finally {
      if (closeClient) httpClient.close();
    }
  }

  UpdateResult _fromRelease(AppVersion current, String body) {
    final dynamic data;
    try {
      data = jsonDecode(body);
    } catch (_) {
      return UpdateResult.unavailable(
        currentVersion,
        'The GitHub release could not be read.',
      );
    }
    if (data is! Map) {
      return UpdateResult.unavailable(
        currentVersion,
        'The GitHub release could not be read.',
      );
    }
    final latest = AppVersion.parse(data['tag_name']?.toString() ?? '');
    if (latest == null) {
      return UpdateResult.unavailable(
        currentVersion,
        'The GitHub release version could not be read.',
      );
    }
    if (!latest.isNewerThan(current)) {
      return UpdateResult.upToDate(currentVersion);
    }
    final pageUrl = githubReleasePage(data['html_url']?.toString());
    final notes = data['body']?.toString().trim() ?? '';
    return UpdateResult.available(
      currentVersion: currentVersion,
      latestVersion: latest.toString(),
      pageUrl: pageUrl,
      notes: notes.length > 800 ? '${notes.substring(0, 800).trim()}…' : notes,
    );
  }
}

/// Release links stay on github.com. Anything else falls back to the releases page.
String githubReleasePage(String? raw) {
  final uri = Uri.tryParse(raw ?? '');
  if (uri != null &&
      uri.isScheme('https') &&
      (uri.host == 'github.com' || uri.host == 'www.github.com')) {
    return uri.toString();
  }
  return githubReleasesPage;
}
