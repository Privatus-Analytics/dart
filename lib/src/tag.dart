import 'attributes.dart';
import 'config.dart';
import 'html.dart';
import 'page_props.dart';

/// The name of the page props function the tracker calls (`data-props`).
const String pagePropsFunction = 'privatusPageProps';

/// The official queue stub. It keeps `privatus.track` and the other calls
/// made before the tracker loads, and the tracker sends them once it is ready.
const String queueStubScript =
    "window.privatus=window.privatus||{q:[]};['track','pageview','props',"
    "'optOut','optIn','ready'].forEach(function(m){window.privatus[m]="
    'window.privatus[m]||function(){window.privatus.q.push([m,'
    'Array.prototype.slice.call(arguments)])}})';

/// The marker the middleware looks for to see if a page already has the tag.
const String trackerPath = '/js/pa.js';

/// Builds the script tag for one page.
///
/// Most code only needs [tag]. This class is there for code that needs the
/// parts, like the Flutter web helper.
class PrivatusTag {
  /// A tag for [config] (default [PrivatusConfig.global]).
  ///
  /// [props] are merged over the configured props, and a null value removes
  /// one. [request] is passed to [PrivatusConfig.propsBuilder]. [nonce] is the
  /// Content Security Policy nonce.
  PrivatusTag({
    PrivatusConfig? config,
    this.nonce,
    this.request,
    this.props,
  }) : config = config ?? PrivatusConfig.global;

  /// The settings this tag uses.
  final PrivatusConfig config;

  /// The Content Security Policy nonce, added to every script.
  final String? nonce;

  /// The request passed to the props builder.
  final Object? request;

  /// Props for this page only, merged over the configured ones.
  final Map<String, Object?>? props;

  /// Whether anything prints: there is a site id and the tag is enabled.
  bool get shouldRender => config.resolvedSiteId != null && config.isEnabled();

  /// The configured props for this request with the per call props on top.
  Map<String, Object?> get pageProps => {
        ..._keyed(config.pageProps(request)),
        ..._keyed(props),
      };

  /// The page props JSON, or null when there are none.
  String? get pagePropsJsonText => pagePropsJson(pageProps);

  /// The tracker script attributes in order. A `true` value is printed as a
  /// bare attribute name (like `defer`).
  Map<String, Object> attributes({bool withProps = false}) {
    final attrs = <String, Object>{
      'defer': true,
      'src': '${config.resolvedScriptHost}$trackerPath',
      'data-site': config.resolvedSiteId ?? '',
    };
    final modules = _list(config.modules);
    if (modules != null) attrs['data-modules'] = modules.join(',');
    final excluded = _list(config.excludedPaths);
    if (excluded != null && excluded.isNotEmpty) {
      attrs['data-exclude'] = excluded.join(',');
    }
    final domains = _list(config.domains);
    if (domains != null && domains.isNotEmpty) {
      attrs['data-domains'] = domains.join(',');
    }
    final spa = config.spa ?? '';
    if (PrivatusConfig.spaModes.contains(spa) && spa != 'auto') {
      attrs['data-spa'] = spa;
    }
    if (config.manual) attrs['data-manual'] = 'true';
    config.extraAttributes.forEach((name, value) {
      if (value != null) attrs[name] = value;
    });
    if (nonce != null) attrs['nonce'] = nonce!;
    if (withProps) attrs['data-props'] = pagePropsFunction;
    return attrs;
  }

  /// The script for the page props function, without the `<script>` tag.
  static String pagePropsScript(String json) =>
      'window.$pagePropsFunction=function(){return $json}';

  /// The HTML: the queue stub and page props scripts when wanted, then the
  /// tracker tag, one per line. Empty when [shouldRender] is false.
  String toHtml() {
    if (!shouldRender) return '';

    final json = pagePropsJsonText;
    return [
      if (config.queueStub) _inlineScript(queueStubScript),
      if (json != null) _inlineScript(pagePropsScript(json)),
      _scriptTag(attributes(withProps: json != null)),
    ].join('\n');
  }

  @override
  String toString() => toHtml();

  String _scriptTag(Map<String, Object> attrs) {
    final parts = attrs.entries.map(
      (entry) => entry.value == true
          ? entry.key
          : '${entry.key}="${escapeHtml(entry.value)}"',
    );
    return '<script ${parts.join(' ')}></script>';
  }

  String _inlineScript(String code) {
    final opening =
        nonce == null ? '<script>' : '<script nonce="${escapeHtml(nonce)}">';
    return '$opening$code</script>';
  }

  static Map<String, Object?> _keyed(Map<String, Object?>? props) => {
        for (final entry in (props ?? const {}).entries)
          normalizeKey(entry.key): entry.value,
      };

  // Null stays null. Anything else becomes a clean list: items are split on
  // commas, trimmed, and empty ones dropped.
  static List<String>? _list(List<String>? values) => values
      ?.expand((item) => item.split(','))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

/// The Privatus Analytics script tag as HTML. Put it in the `<head>`.
///
/// ```dart
/// tag()
/// // <script defer src="https://privatusstats.com/js/pa.js" data-site="pa_YOURSITEID"></script>
/// ```
///
/// Every argument is optional and changes only this call: [config] replaces
/// [PrivatusConfig.global], the named settings override it, [props] are
/// merged over the configured props (a null value removes one), [request] is
/// passed to the props builder and [nonce] is your Content Security Policy
/// nonce.
///
/// Prints nothing without a site id or when the tag is not enabled.
String tag({
  PrivatusConfig? config,
  String? nonce,
  Object? request,
  Map<String, Object?>? props,
  List<String>? modules,
  List<String>? excludedPaths,
  List<String>? domains,
  String? spa,
  bool? manual,
  bool? enabled,
  Map<String, Object?>? extraAttributes,
  bool? queueStub,
}) {
  final settings = (config ?? PrivatusConfig.global).copyWith(
    modules: modules,
    excludedPaths: excludedPaths,
    domains: domains,
    spa: spa,
    manual: manual,
    enabled: enabled,
    extraAttributes: extraAttributes,
    queueStub: queueStub,
  );
  return PrivatusTag(
    config: settings,
    nonce: nonce,
    request: request,
    props: props,
  ).toHtml();
}
