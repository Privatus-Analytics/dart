// A Dart web app (Flutter web works the same way) that adds the tracker at
// runtime. Build it with:
//   dart compile js -DPRIVATUS_SITE_ID=pa_YOURSITEID -o main.dart.js example/web/main.dart
import 'package:privatus_analytics/web.dart';

void main() {
  injectTracker(
    config: const PrivatusConfig(queueStub: true, spa: 'hash'),
    props: const {'app_version': '2.4'},
  );
  track('App opened', {'theme': 'dark'});
}
