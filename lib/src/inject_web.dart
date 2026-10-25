import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import 'attributes.dart';
import 'config.dart';
import 'tag.dart';

/// Adds the tracker to the current web page at runtime, like the [tag] would
/// in the HTML: the queue stub and page props scripts when wanted, then the
/// tracker script, all in `document.head`.
///
/// Returns true when it added the tracker. Returns false and adds nothing
/// when there is no site id, when the tag is not enabled (by default only
/// release builds are), or when the page already loads `/js/pa.js`.
bool injectTracker({
  PrivatusConfig? config,
  Map<String, Object?>? props,
  String? nonce,
}) {
  final tracker = PrivatusTag(config: config, props: props, nonce: nonce);
  if (!tracker.shouldRender) return false;
  if (web.document.querySelector('script[src*="$trackerPath"]') != null) {
    return false;
  }

  final head = web.document.head;
  if (head == null) return false;

  void inline(String code) {
    final script = web.document.createElement('script');
    if (nonce != null) script.setAttribute('nonce', nonce);
    script.textContent = code;
    head.append(script);
  }

  final json = tracker.pagePropsJsonText;
  if (tracker.config.queueStub) inline(queueStubScript);
  if (json != null) inline(PrivatusTag.pagePropsScript(json));

  final script = web.document.createElement('script');
  tracker.attributes(withProps: json != null).forEach((name, value) {
    script.setAttribute(name, value == true ? '' : '$value');
  });
  head.append(script);
  return true;
}

/// Sends a custom event from Dart through the tracker's `privatus.track`.
///
/// The name and props follow the same rules as [eventData]. Returns false
/// when the tracker (or the queue stub) is not on the page.
bool track(String name, [Map<String, Object?>? props]) {
  if (!globalContext.has('privatus')) return false;
  final privatus = globalContext.getProperty<JSObject>('privatus'.toJS);
  final data = eventData(name, props);
  final event = data['data-privatus-event'];
  if (event == null) return false;

  final clean = <String, String>{
    for (final entry in data.entries)
      if (entry.key.startsWith('data-privatus-prop-'))
        entry.key.substring('data-privatus-prop-'.length): entry.value,
  };
  final args = <JSAny?>[event.toJS, if (clean.isNotEmpty) _toJs(clean)];
  privatus.callMethodVarArgs<JSAny?>('track'.toJS, args);
  return true;
}

JSAny? _toJs(Map<String, String> props) =>
    (jsonDecode(jsonEncode(props)) as Object).jsify();
