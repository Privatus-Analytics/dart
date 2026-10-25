import 'dart:convert';

import 'package:shelf/shelf.dart';

import 'config.dart';
import 'tag.dart';

/// The `context` key the middleware reads the Content Security Policy nonce
/// from, on the request or on the response.
const String privatusNonceKey = 'privatus.nonce';

final RegExp _headClose = RegExp('</head>', caseSensitive: false);

/// A shelf middleware that adds the script tag just before `</head>` in HTML
/// responses.
///
/// It only changes responses with status 200 and a `text/html` content type,
/// with no `Content-Encoding`, to requests that are not Ajax
/// (`X-Requested-With: XMLHttpRequest`), and only pages that have a `</head>`
/// and do not already load `/js/pa.js`. It sets the new `Content-Length`.
///
/// [config] defaults to [PrivatusConfig.global] at the time of each request.
/// The props builder gets the shelf `Request`. The nonce comes from [nonce],
/// else from `context[privatusNonceKey]` on the response, then the request.
Middleware privatusMiddleware({
  PrivatusConfig? config,
  String? Function(Request request)? nonce,
}) {
  return (Handler inner) {
    return (Request request) async {
      final response = await inner(request);
      final settings = config ?? PrivatusConfig.global;
      if (!_shouldInject(request, response, settings)) return response;

      final html = await response.readAsString();
      final match = _headClose.firstMatch(html);
      if (match == null || html.contains(trackerPath)) {
        return response.change(body: html);
      }

      final snippet = PrivatusTag(
        config: settings,
        request: request,
        nonce: nonce?.call(request) ??
            _contextNonce(response.context) ??
            _contextNonce(request.context),
      ).toHtml();
      final body =
          '${html.substring(0, match.start)}$snippet\n</head>${html.substring(match.end)}';
      final encoding = response.encoding ?? utf8;
      return response.change(
        body: body,
        headers: {'content-length': '${encoding.encode(body).length}'},
      );
    };
  };
}

bool _shouldInject(Request request, Response response, PrivatusConfig config) {
  if (response.statusCode != 200) return false;
  final type = response.headers['content-type']?.toLowerCase() ?? '';
  if (!type.startsWith('text/html')) return false;
  if (response.headers['content-encoding'] != null) return false;
  final requestedWith = request.headers['x-requested-with'] ?? '';
  if (requestedWith.toLowerCase() == 'xmlhttprequest') return false;
  return PrivatusTag(config: config).shouldRender;
}

String? _contextNonce(Map<String, Object> context) {
  final value = context[privatusNonceKey];
  return value is String && value.isNotEmpty ? value : null;
}
