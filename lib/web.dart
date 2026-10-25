/// Adds the Privatus Analytics tracker to a page at runtime, for Flutter web
/// and other Dart web apps.
///
/// It is safe to import everywhere: off the web the functions do nothing.
/// Only websites are counted. Flutter apps for phones and desktops are not.
///
/// ```dart
/// import 'package:privatus_analytics/web.dart';
///
/// void main() {
///   injectTracker(config: const PrivatusConfig(siteId: 'pa_YOURSITEID'));
///   runApp(const MyApp());
/// }
/// ```
library;

export 'privatus_analytics.dart';
export 'src/inject_stub.dart' if (dart.library.js_interop) 'src/inject_web.dart'
    show injectTracker, track;
