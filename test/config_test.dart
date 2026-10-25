import 'dart:io';

import 'package:privatus_analytics/privatus_analytics.dart';
import 'package:test/test.dart';

Future<String> probe(Map<String, String> environment) async {
  final result = await Process.run(
    Platform.resolvedExecutable,
    ['run', 'test/support/env_probe.dart'],
    environment: {
      'PRIVATUS_SITE_ID': '',
      'PRIVATUS_SCRIPT_HOST': '',
      'PRIVATUS_ENV': '',
      'APP_ENV': '',
      'DART_ENV': '',
      ...environment,
    },
  );
  expect(result.exitCode, 0, reason: '${result.stderr}');
  return (result.stdout as String).trim();
}

void main() {
  test('site id is null by default', () {
    expect(const PrivatusConfig().resolvedSiteId, isNull);
    expect(const PrivatusConfig(siteId: '  ').resolvedSiteId, isNull);
  });

  test('an explicit site id is trimmed', () {
    expect(const PrivatusConfig(siteId: ' pa_X ').resolvedSiteId, 'pa_X');
  });

  test('script host defaults and drops a trailing slash', () {
    expect(
        const PrivatusConfig().resolvedScriptHost, 'https://privatusstats.com');
    expect(
      const PrivatusConfig(scriptHost: 'https://stats.example.com/')
          .resolvedScriptHost,
      'https://stats.example.com',
    );
  });

  test('only production is enabled by default', () {
    const config = PrivatusConfig();
    expect(config.isEnabled('production'), isTrue);
    expect(config.isEnabled('development'), isFalse);
    expect(config.isEnabled('test'), isFalse);
  });

  test('enabled forces the tag on or off', () {
    expect(
        const PrivatusConfig(enabled: true).isEnabled('development'), isTrue);
    expect(
        const PrivatusConfig(enabled: false).isEnabled('production'), isFalse);
  });

  test('the environment setting wins', () {
    expect(const PrivatusConfig(environment: 'production').isEnabled(), isTrue);
    expect(
      const PrivatusConfig(
        environment: 'staging',
        enabledEnvironments: ['production', 'staging'],
      ).isEnabled(),
      isTrue,
    );
  });

  test('dart run is development by default', () {
    expect(const PrivatusConfig().resolvedEnvironment, 'development');
  });

  test('props and queue stub are off by default', () {
    expect(const PrivatusConfig().pageProps(), isEmpty);
    expect(const PrivatusConfig().queueStub, isFalse);
  });

  test('the props builder gets the request and is merged over props', () {
    final config = PrivatusConfig(
      props: const {'plan': 'free', 'role': 'admin'},
      propsBuilder: (request) => {'plan': request},
    );
    expect(config.pageProps('pro'), {'plan': 'pro', 'role': 'admin'});
  });

  test('copyWith keeps unchanged settings', () {
    const config = PrivatusConfig(siteId: 'pa_X', modules: ['engage']);
    final copy = config.copyWith(spa: 'hash');
    expect(copy.siteId, 'pa_X');
    expect(copy.modules, ['engage']);
    expect(copy.spa, 'hash');
  });

  group('environment variables', () {
    test('nothing set', () async {
      expect(
          await probe({}), 'null|https://privatusstats.com|development|false');
    });

    test('site id, script host and environment come from the environment',
        () async {
      expect(
        await probe({
          'PRIVATUS_SITE_ID': 'pa_FROMENV123',
          'PRIVATUS_SCRIPT_HOST': 'https://stats.example.com/',
          'APP_ENV': 'production',
        }),
        'pa_FROMENV123|https://stats.example.com|production|true',
      );
    });

    test('PRIVATUS_ENV comes before APP_ENV and DART_ENV', () async {
      expect(
        await probe({'PRIVATUS_ENV': 'staging', 'DART_ENV': 'production'}),
        endsWith('|staging|false'),
      );
    });
  });
}
