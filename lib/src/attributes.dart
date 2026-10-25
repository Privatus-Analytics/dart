import 'dart:developer' as developer;

import 'html.dart';

/// Longest event name kept.
const int maxEventName = 120;

/// Longest prop key kept.
const int maxPropKey = 64;

/// Most props kept per event or page.
const int maxProps = 30;

/// Longest prop value kept.
const int maxPropValue = 500;

final RegExp _clickName = RegExp(r'^[A-Za-z0-9_.:-]{1,100}$');
final RegExp _badKeyChar = RegExp(r'[^a-z0-9_]', unicode: true);

/// The data attributes for a custom event, with full attribute names:
///
/// ```dart
/// eventData('Report exported', {'format': 'csv'})
/// // {'data-privatus-event': 'Report exported', 'data-privatus-prop-format': 'csv'}
/// ```
///
/// Returns an empty map when the name is empty. Handy for components that
/// take an attributes map, like Jaspr's.
Map<String, String> eventData(String? name, [Map<String, Object?>? props]) {
  final clean = cut((name ?? '').trim(), maxEventName).trim();
  if (clean.isEmpty) return {};

  final attrs = <String, String>{'data-privatus-event': clean};
  normalizeProps(props).forEach((key, value) {
    attrs['data-privatus-prop-$key'] = _stringValue(value);
  });
  return attrs;
}

/// The data attributes for a custom event, as escaped HTML to put inside a
/// tag:
///
/// ```dart
/// '<button ${eventAttrs('Report exported', {'format': 'csv'})}>Export</button>'
/// ```
///
/// On a `<form>` the event is sent when the form is submitted. Returns an
/// empty string when the name is empty.
String eventAttrs(String? name, [Map<String, Object?>? props]) =>
    attributesToHtml(eventData(name, props));

/// Whether [name] is a valid click map name: letters, digits and `_ . : -`,
/// at most 100 characters.
bool isValidClickName(String? name) =>
    name != null && _clickName.hasMatch(name);

/// The click map name attribute, `{'data-privatus-click': name}`, or an empty
/// map when the name is not valid.
Map<String, String> clickData(String? name) {
  if (isValidClickName(name)) return {'data-privatus-click': name!};
  assert(() {
    developer.log(
      'click map name ${name == null ? 'null' : '"$name"'} is not valid. Use '
      'letters, digits and _ . : - only, at most 100 characters. Nothing was '
      'printed.',
      name: 'privatus_analytics',
    );
    return true;
  }());
  return {};
}

/// The click map name attribute as escaped HTML:
/// `data-privatus-click="pricing.cta"`. Empty when the name is not valid.
String clickAttr(String? name) => attributesToHtml(clickData(name));

/// Turns an attribute map into HTML, with every value escaped.
String attributesToHtml(Map<String, String> attrs) => attrs.entries
    .map((entry) => '${entry.key}="${escapeHtml(entry.value)}"')
    .join(' ');

/// Cleans a prop key: lowercase, anything outside a-z 0-9 _ becomes `_`, cut
/// to 64 characters.
String normalizeKey(Object? key) {
  final clean = '${key ?? ''}'.toLowerCase().replaceAll(_badKeyChar, '_');
  return clean.length > maxPropKey ? clean.substring(0, maxPropKey) : clean;
}

/// Cleans props: keys go through [normalizeKey], null values and empty keys
/// are dropped, and the first 30 are kept.
Map<String, Object> normalizeProps(Map<String, Object?>? props) {
  final clean = <String, Object>{};
  props?.forEach((key, value) {
    final name = normalizeKey(key);
    if (name.isNotEmpty && value != null) clean[name] = value;
  });
  if (clean.length <= maxProps) return clean;
  return Map.fromEntries(clean.entries.take(maxProps));
}

String _stringValue(Object value) {
  final text = value is Iterable<Object?>
      ? value.where((item) => item != null).join(',')
      : '$value';
  return cut(text, maxPropValue);
}
