import 'config.dart';

/// Adds the tracker to the current web page. Off the web (the Dart VM, a
/// server, or a Flutter mobile app) it does nothing and returns false.
bool injectTracker({
  PrivatusConfig? config,
  Map<String, Object?>? props,
  String? nonce,
}) =>
    false;

/// Sends a custom event from Dart through the tracker's `privatus.track`.
/// Off the web it does nothing and returns false.
bool track(String name, [Map<String, Object?>? props]) => false;
