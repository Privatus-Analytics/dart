// Used on the web, where there are no process environment variables. Values
// come from `--dart-define` at build time.

/// The value of a supported setting from `--dart-define`, or null.
String? readEnvironment(String name) {
  final value = switch (name) {
    'PRIVATUS_SITE_ID' => const String.fromEnvironment('PRIVATUS_SITE_ID'),
    'PRIVATUS_SCRIPT_HOST' =>
      const String.fromEnvironment('PRIVATUS_SCRIPT_HOST'),
    'PRIVATUS_ENV' => const String.fromEnvironment('PRIVATUS_ENV'),
    'APP_ENV' => const String.fromEnvironment('APP_ENV'),
    'DART_ENV' => const String.fromEnvironment('DART_ENV'),
    _ => '',
  };
  return value.trim().isEmpty ? null : value.trim();
}
