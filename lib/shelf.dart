/// A shelf middleware that adds the Privatus Analytics script tag to the
/// head of your HTML responses.
///
/// ```dart
/// import 'package:privatus_analytics/shelf.dart';
///
/// final handler = const Pipeline()
///     .addMiddleware(privatusMiddleware())
///     .addHandler(app);
/// ```
library;

export 'privatus_analytics.dart';
export 'src/middleware.dart' show privatusMiddleware, privatusNonceKey;
