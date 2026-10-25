import 'package:privatus_analytics/privatus_analytics.dart';
import 'package:test/test.dart';

const snippet =
    '<script defer src="https://privatusstats.com/js/pa.js" data-site="pa_TEST123456"></script>';

void main() {
  setUp(() {
    PrivatusConfig.global =
        const PrivatusConfig(siteId: 'pa_TEST123456', enabled: true);
  });

  tearDown(() => PrivatusConfig.global = const PrivatusConfig());

  void configure(PrivatusConfig config) => PrivatusConfig.global = config;

  test('prints the basic snippet', () {
    expect(tag(), snippet);
    expect(PrivatusTag().toString(), snippet);
  });

  test('prints nothing without a site id', () {
    configure(const PrivatusConfig(enabled: true));
    expect(tag(), '');
  });

  test('prints nothing outside the enabled environments', () {
    configure(const PrivatusConfig(siteId: 'pa_TEST123456'));
    expect(tag(), '');
  });

  test('adds modules and exclusions', () {
    final html = tag(
      modules: ['engage', 'auto'],
      excludedPaths: ['/admin/*', '/preview/*'],
    );
    expect(html, contains('data-modules="engage,auto"'));
    expect(html, contains('data-exclude="/admin/*,/preview/*"'));
  });

  test('an empty modules list loads none', () {
    expect(tag(modules: []), contains('data-modules=""'));
  });

  test('adds domains, spa mode and manual mode', () {
    final html = tag(
      domains: ['example.com, www.example.com'],
      spa: 'hash',
      manual: true,
    );
    expect(html, contains('data-domains="example.com,www.example.com"'));
    expect(html, contains('data-spa="hash"'));
    expect(html, contains('data-manual="true"'));
  });

  test('ignores an unknown spa mode and the auto default', () {
    expect(tag(spa: 'bogus'), isNot(contains('data-spa')));
    expect(tag(spa: 'auto'), isNot(contains('data-spa')));
  });

  test('escapes attribute values', () {
    expect(tag(excludedPaths: ['/a"b']), contains('data-exclude="/a&quot;b"'));
  });

  test('per call options override the configuration', () {
    configure(const PrivatusConfig(
      siteId: 'pa_TEST123456',
      enabled: true,
      modules: ['engage'],
    ));
    expect(tag(modules: ['vitals']), contains('data-modules="vitals"'));
    expect(tag(enabled: false), '');
  });

  test('a config argument replaces the global one', () {
    expect(
      tag(config: const PrivatusConfig(siteId: 'pa_OTHER', enabled: true)),
      contains('data-site="pa_OTHER"'),
    );
  });

  test('adds extra attributes and a nonce', () {
    final html = tag(
      extraAttributes: {
        'data-mask': '/orders/*->/orders/:id',
        'data-debug': true,
        'data-gone': null,
      },
      nonce: 'abc123',
    );
    expect(html, contains('data-mask="/orders/*-&gt;/orders/:id"'));
    expect(html, contains(' data-debug '));
    expect(html, isNot(contains('data-gone')));
    expect(html, contains('nonce="abc123"'));
  });

  test('page props print an inline script before the tag and data-props on it',
      () {
    expect(
      tag(props: {'plan': 'pro', 'role': 'admin'}),
      '<script>window.privatusPageProps=function(){return '
      '{"plan":"pro","role":"admin"}}</script>\n'
      '<script defer src="https://privatusstats.com/js/pa.js" '
      'data-site="pa_TEST123456" data-props="privatusPageProps"></script>',
    );
  });

  test('the props script gets the nonce', () {
    expect(
      tag(props: {'plan': 'pro'}, nonce: 'abc'),
      startsWith('<script nonce="abc">window.privatusPageProps='),
    );
  });

  test('empty props print no script and no data-props', () {
    expect(tag(props: {'plan': null}), snippet);
  });

  test('configured props can be a map', () {
    configure(const PrivatusConfig(
      siteId: 'pa_TEST123456',
      enabled: true,
      props: {'plan': 'pro'},
    ));
    expect(tag(), contains('{"plan":"pro"}'));
  });

  test('configured props can be built from the request', () {
    configure(PrivatusConfig(
      siteId: 'pa_TEST123456',
      enabled: true,
      propsBuilder: (request) => {'plan': (request as Map)['plan']},
    ));
    expect(tag(request: {'plan': 'team'}), contains('{"plan":"team"}'));
  });

  test('per call props are merged over configured props and null removes one',
      () {
    configure(const PrivatusConfig(
      siteId: 'pa_TEST123456',
      enabled: true,
      props: {'plan': 'pro', 'role': 'admin'},
    ));
    expect(
      tag(props: {'Role': null, 'tier': 'gold'}),
      contains('{"plan":"pro","tier":"gold"}'),
    );
  });

  test('the props builder is not called when the tag is off', () {
    configure(PrivatusConfig(
      siteId: 'pa_TEST123456',
      enabled: false,
      propsBuilder: (_) => throw StateError('should not run'),
    ));
    expect(tag(), '');
  });

  test('queue stub prints the official stub first', () {
    final parts =
        tag(queueStub: true, nonce: 'abc', props: {'plan': 'pro'}).split('\n');
    expect(parts[0], '<script nonce="abc">$queueStubScript</script>');
    expect(parts[1], contains('privatusPageProps'));
    expect(parts[2], contains('/js/pa.js'));
  });

  test('the queue stub is the official one', () {
    expect(
      queueStubScript,
      "window.privatus=window.privatus||{q:[]};['track','pageview','props',"
      "'optOut','optIn','ready'].forEach(function(m){window.privatus[m]="
      'window.privatus[m]||function(){window.privatus.q.push([m,'
      'Array.prototype.slice.call(arguments)])}})',
    );
  });

  test('queue stub can be switched on per call', () {
    expect(tag(queueStub: true), contains('q:[]'));
    expect(tag(), isNot(contains('q:[]')));
  });

  group('when the tag is off', () {
    test('off with the queue stub on prints only the stub, with the nonce', () {
      var called = false;
      final html = tag(
        config: PrivatusConfig(
          siteId: 'pa_TEST123456',
          enabled: false,
          queueStub: true,
          propsBuilder: (_) {
            called = true;
            return {'plan': 'pro'};
          },
        ),
        nonce: 'abc',
        props: {'role': 'admin'},
      );
      expect(html, '<script nonce="abc">$queueStubScript</script>');
      expect(called, isFalse, reason: 'the props builder must not run');
    });

    test('off with the queue stub on and no nonce prints the bare stub', () {
      expect(
        tag(enabled: false, queueStub: true, props: {'plan': 'pro'}),
        '<script>$queueStubScript</script>',
      );
    });

    test('off with the queue stub off prints nothing', () {
      expect(tag(enabled: false, queueStub: false, props: {'plan': 'pro'}), '');
    });

    test('no site id with the queue stub on prints only the stub', () {
      configure(const PrivatusConfig(enabled: true));
      expect(
        tag(queueStub: true, nonce: 'abc', props: {'plan': 'pro'}),
        '<script nonce="abc">$queueStubScript</script>',
      );
    });

    test('the default environment gating counts as off', () {
      configure(const PrivatusConfig(
        siteId: 'pa_TEST123456',
        environment: 'development',
        queueStub: true,
      ));
      expect(tag(), '<script>$queueStubScript</script>');
    });
  });
}
