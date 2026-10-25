// A small shelf server that shows the tag, an event button and a click map
// name. Run it with: dart run example/main.dart
import 'dart:io';

import 'package:privatus_analytics/shelf.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

Future<void> main() async {
  PrivatusConfig.global = PrivatusConfig(
    siteId: 'pa_YOURSITEID',
    // On while you try it. Leave this out to print the tag only in production.
    enabled: true,
    modules: const ['engage', 'auto'],
    propsBuilder: (request) => {'section': (request as Request).url.path},
  );

  final handler = const Pipeline()
      .addMiddleware(privatusMiddleware())
      .addHandler((request) => Response.ok(
            '''
<!doctype html>
<html>
<head><title>Privatus example</title></head>
<body>
  <button ${eventAttrs('Report exported', {'format': 'csv'})}>Export</button>
  <a href="/pricing" ${clickAttr('pricing.cta')}>See plans</a>
</body>
</html>
''',
            headers: {'content-type': 'text/html; charset=utf-8'},
          ));

  final server = await io.serve(handler, InternetAddress.loopbackIPv4, 8080);
  stdout.writeln('Open http://localhost:${server.port}');
}
