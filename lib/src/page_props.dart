import 'dart:convert';

import 'attributes.dart';
import 'html.dart';

/// Most items kept in a list prop.
const int maxListItems = 30;

final RegExp _unsafe = RegExp('[<>&\u2028\u2029]');

/// Turns page props (plan, role and so on) into a JSON object that is safe
/// inside a `<script>`, or null when there are no props to send.
///
/// Keys follow the same rules as event props. Numbers, booleans and lists
/// keep their JSON types. `<`, `>`, `&`, U+2028 and U+2029 are written as
/// `\u003c` and so on.
String? pagePropsJson(Map<String, Object?>? props) {
  final clean = <String, Object>{};
  normalizeProps(props).forEach((key, value) {
    final json = _jsonValue(value);
    if (json != null) clean[key] = json;
  });
  if (clean.isEmpty) return null;

  return jsonEncode(clean).replaceAllMapped(
    _unsafe,
    (match) =>
        '\\u${match[0]!.codeUnitAt(0).toRadixString(16).padLeft(4, '0')}',
  );
}

Object? _jsonValue(Object value) {
  if (value is Iterable<Object?>) {
    return value
        .where((item) => item != null)
        .take(maxListItems)
        .map(_scalar)
        .whereType<Object>()
        .toList();
  }
  return _scalar(value);
}

Object? _scalar(Object? value) {
  if (value == null) return null;
  if (value is bool || value is int) return value;
  if (value is double) return value.isFinite ? value : null;
  return cut('$value', maxPropValue);
}
