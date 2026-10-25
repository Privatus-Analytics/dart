// The example app for the Privatus Analytics conformance tests
// (https://github.com/Privatus-Analytics/conformance). The suite builds it
// with example/Dockerfile and checks every route in a real browser; its
// CONTRACT.md says what each route must print. The site id and script host
// come from PRIVATUS_SITE_ID and PRIVATUS_SCRIPT_HOST.
//
// Run it yourself with: dart run example/conformance.dart
import 'dart:io';

import 'package:privatus_analytics/shelf.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

const nonce = 'testnonce';
const nasty = '</script><script>window.__pwned=1</script>  &<>"\'';
const pageProps = <String, Object?>{
  'plan': 'pro',
  'role': 'admin',
  'beta': true,
  'seats': 3,
};

const autoPage = '''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Auto inject</title>
</head>
<body><h1>Auto inject</h1><p>No tag in the template. The middleware adds it.</p></body>
</html>
''';

String layout(String title, String body, {Map<String, Object?>? props}) => '''
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>$title</title>
${tag(props: props ?? pageProps, queueStub: true, nonce: nonce)}
</head>
<body>
$body
</body>
</html>
''';

String offPage({required bool queueStub}) => '''
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Off</title>
<meta name="privatus-off-start">${tag(enabled: false, props: pageProps, queueStub: queueStub, nonce: nonce)}<meta name="privatus-off-end">
</head>
<body><h1>Off</h1></body>
</html>
''';

Response page(String html) =>
    Response.ok(html, headers: {'content-type': 'text/html; charset=utf-8'});

Future<void> main() async {
  // Forced on, so the tag prints whatever the environment. The site id and
  // script host come from the environment.
  PrivatusConfig.global = const PrivatusConfig(enabled: true);
  final scriptHost = PrivatusConfig.global.resolvedScriptHost;

  // Auto inject on /auto only, so the other routes test tag() alone.
  final auto = const Pipeline()
      .addMiddleware(privatusMiddleware(nonce: (_) => nonce))
      .addHandler((_) => page(autoPage));

  Future<Response> app(Request request) async {
    switch (request.url.path) {
      case '':
        return page(layout('Home', '<h1>Home</h1>'));
      case 'event':
        return page(layout('Events', '''
<h1>Events</h1>
<button type="button" ${eventAttrs('Report exported', {
              'format': 'csv',
              'source': 'toolbar'
            })}>Export report</button>
<p><a href="#pricing" ${clickAttr('pricing.cta')}>Pricing</a></p>
<form action="/event" method="get" ${eventAttrs('Signup form')}>
  <button type="submit">Sign up</button>
</form>'''));
      case 'nasty':
        return page(layout(
          'Nasty',
          '<h1>Nasty values</h1>\n'
              '<button type="button" ${eventAttrs('Nasty value', {
                'nasty': nasty
              })}>Nasty</button>',
          props: {...pageProps, 'nasty': nasty},
        ));
      // Off with the queue stub on prints only the stub, so privatus.track
      // calls still work. Off without it prints nothing.
      case 'off':
        return page(offPage(queueStub: true));
      case 'off-plain':
        return page(offPage(queueStub: false));
      case 'auto':
        return auto(request);
      default:
        return Response.notFound('Not found');
    }
  }

  final handler = const Pipeline().addMiddleware((inner) {
    return (request) async {
      final response = await inner(request);
      return response.change(headers: {
        'content-security-policy': "script-src 'nonce-$nonce' $scriptHost",
      });
    };
  }).addHandler(app);

  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
  stdout.writeln('Example app on port ${server.port}');
}
