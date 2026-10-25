import 'dart:convert';

import 'package:privatus_analytics/shelf.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

const snippet =
    '<script defer src="https://privatusstats.com/js/pa.js" data-site="pa_TEST123456"></script>';
const page = '<html><head><title>Hi</title></head><body>Hi</body></html>';
const on = PrivatusConfig(siteId: 'pa_TEST123456', enabled: true);

Future<Response> run(
  Response response, {
  PrivatusConfig config = on,
  Map<String, String>? headers,
  Map<String, Object>? context,
  String? Function(Request)? nonce,
}) {
  final handler = const Pipeline()
      .addMiddleware(privatusMiddleware(config: config, nonce: nonce))
      .addHandler((_) => response);
  return Future.value(handler(Request(
    'GET',
    Uri.parse('http://localhost/plain?plan=pro'),
    headers: headers,
    context: context,
  )));
}

Response html(String body, {Map<String, String> headers = const {}}) =>
    Response.ok(body,
        headers: {'content-type': 'text/html; charset=utf-8', ...headers});

void main() {
  test('adds the tag before the head closes and fixes Content-Length',
      () async {
    final response = await run(html(page));
    final body = await response.readAsString();
    expect(body, contains('$snippet\n</head>'));
    expect(response.headers['content-length'], '${utf8.encode(body).length}');
  });

  test('counts bytes, not characters, for Content-Length', () async {
    final response =
        await run(html('<html><HEAD></HEAD><body>héllo 😀</body></html>'));
    final body = await response.readAsString();
    expect(body, contains('$snippet\n</head>'));
    expect(response.headers['content-length'], '${utf8.encode(body).length}');
  });

  test('does not add a second tag', () async {
    final response = await run(html('<head>$snippet</head>'));
    expect(await response.readAsString(), '<head>$snippet</head>');
  });

  test('leaves JSON alone', () async {
    final response = await run(Response.ok('{"a":"</head>"}',
        headers: {'content-type': 'application/json'}));
    expect(await response.readAsString(), '{"a":"</head>"}');
  });

  test('leaves HTML without a head alone', () async {
    final response = await run(html('<p>No head here</p>'));
    expect(await response.readAsString(), '<p>No head here</p>');
  });

  test('leaves Ajax requests alone', () async {
    final response =
        await run(html(page), headers: {'X-Requested-With': 'XMLHttpRequest'});
    expect(await response.readAsString(), page);
  });

  test('leaves other statuses and encoded responses alone', () async {
    final missing = await run(
        Response.notFound(page, headers: {'content-type': 'text/html'}));
    expect(await missing.readAsString(), page);

    final encoded =
        await run(html(page, headers: {'content-encoding': 'gzip'}));
    expect(await encoded.readAsString(), page);
  });

  test('adds nothing outside the enabled environments', () async {
    final response = await run(html(page),
        config: const PrivatusConfig(siteId: 'pa_TEST123456'));
    expect(await response.readAsString(), page);
  });

  test('uses the global config when none is given', () async {
    PrivatusConfig.global = on;
    addTearDown(() => PrivatusConfig.global = const PrivatusConfig());
    final handler = const Pipeline()
        .addMiddleware(privatusMiddleware())
        .addHandler((_) => html(page));
    final response =
        await handler(Request('GET', Uri.parse('http://localhost/')));
    expect(await response.readAsString(), contains(snippet));
  });

  test('the props builder gets the shelf request', () async {
    Object? seen;
    final config = on.copyWith(propsBuilder: (request) {
      seen = request;
      return {'plan': (request as Request).url.queryParameters['plan']};
    });
    final body = await (await run(html(page), config: config)).readAsString();
    expect(seen, isA<Request>());
    expect(body,
        contains('window.privatusPageProps=function(){return {"plan":"pro"}}'));
    expect(body, contains('data-props="privatusPageProps"'));
  });

  test('adds the nonce from the request context and the queue stub', () async {
    final config = on.copyWith(queueStub: true, props: {'plan': 'pro'});
    final response = await run(html(page),
        config: config, context: {privatusNonceKey: 'n0nce'});
    final body = await response.readAsString();
    expect('nonce="n0nce"'.allMatches(body), hasLength(3));
    expect(body, contains('q:[]'));
    expect(response.headers['content-length'], '${utf8.encode(body).length}');
  });

  test('a nonce on the response context or from the callback works', () async {
    final fromResponse =
        await run(html(page).change(context: {privatusNonceKey: 'resp'}));
    expect(await fromResponse.readAsString(), contains('nonce="resp"'));

    final fromCallback = await run(html(page), nonce: (_) => 'cb');
    expect(await fromCallback.readAsString(), contains('nonce="cb"'));
  });

  test('inserts nothing when the tag is off, even with the queue stub on',
      () async {
    final response = await run(
      html(page),
      config: on.copyWith(enabled: false, queueStub: true),
    );
    expect(await response.readAsString(), page);
  });
}
