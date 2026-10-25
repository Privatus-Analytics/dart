import 'package:privatus_analytics/privatus_analytics.dart';

// Prints what the config reads from the environment. Used by config_test.
void main() {
  const config = PrivatusConfig();
  // ignore: avoid_print
  print([
    config.resolvedSiteId,
    config.resolvedScriptHost,
    config.resolvedEnvironment,
    config.isEnabled(),
  ].join('|'));
}
