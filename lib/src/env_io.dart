import 'dart:io' show Platform;

import 'env_stub.dart' as defines;

/// The value of an environment variable, then of `--dart-define`, or null.
String? readEnvironment(String name) {
  final value = Platform.environment[name]?.trim() ?? '';
  return value.isEmpty ? defines.readEnvironment(name) : value;
}
