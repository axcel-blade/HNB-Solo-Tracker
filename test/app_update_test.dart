import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hnb_solo_tracker/services/app_update.dart';
import 'package:http/http.dart' as http;

void main() {
  test('version comparison ignores a leading v and an older release', () {
    expect(AppVersion.parse('v1.2.0').toString(), '1.2.0');
    expect(AppVersion.parse('1.0.0+1').toString(), '1.0.0');
    expect(AppVersion.parse('latest'), isNull);
    final current = AppVersion.parse('1.0.0')!;
    expect(AppVersion.parse('1.0.0')!.isNewerThan(current), isFalse);
    expect(AppVersion.parse('1.0.1')!.isNewerThan(current), isTrue);
    expect(AppVersion.parse('1.1.0')!.isNewerThan(current), isTrue);
    expect(
      AppVersion.parse('2.0.0')!.isNewerThan(AppVersion.parse('1.9.9')!),
      isTrue,
    );
  });

  test('github release pages stay on github.com', () {
    expect(
      githubReleasePage(
        'https://github.com/axcel-blade/HNB-Solo-Tracker/releases/tag/v1.2.0',
      ),
      contains('github.com/axcel-blade'),
    );
    expect(githubReleasePage('https://example.com/evil'), githubReleasesPage);
  });

  test(
    'a newer GitHub release is reported and the same version is current',
    () async {
      final tags = ['v1.2.0', 'v1.0.0'];
      var index = 0;
      final client = _StubClient((request) async {
        expect(
          request.url.path,
          '/repos/axcel-blade/HNB-Solo-Tracker/releases/latest',
        );
        expect(request.headers['user-agent'], 'hnb-solo-tracker');
        final tag = tags[index];
        index += 1;
        return http.Response(
          jsonEncode({
            'tag_name': tag,
            'html_url':
                'https://github.com/axcel-blade/HNB-Solo-Tracker/releases/tag/$tag',
            'body': 'Notes',
          }),
          200,
        );
      });
      addTearDown(client.close);

      final newer = await GithubUpdateChecker(
        currentVersion: '1.0.0',
        client: client,
      ).check();
      expect(newer.status, UpdateStatus.available);
      expect(newer.latestVersion, '1.2.0');
      expect(newer.pageUrl, contains('github.com'));

      final same = await GithubUpdateChecker(
        currentVersion: '1.0.0',
        client: client,
      ).check();
      expect(same.status, UpdateStatus.upToDate);
    },
  );

  test('a missing release does not throw', () async {
    final client = _StubClient((_) async => http.Response('missing', 404));
    addTearDown(client.close);
    final result = await GithubUpdateChecker(
      currentVersion: '1.0.0',
      client: client,
    ).check();
    expect(result.status, UpdateStatus.unavailable);
    expect(result.message, contains('No GitHub release'));
  });
}

class _StubClient extends http.BaseClient {
  _StubClient(this._handler);

  final Future<http.Response> Function(http.Request request) _handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _handler(request as http.Request);
    return http.StreamedResponse(
      Stream<List<int>>.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }
}
