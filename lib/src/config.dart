import 'env_stub.dart' if (dart.library.io) 'env_io.dart';

/// Builds page props for one request, for example from the signed-in account.
///
/// In the shelf middleware the request is a shelf `Request`. With [tag] it is
/// whatever you pass as `request`, or null.
typedef PagePropsBuilder = Map<String, Object?>? Function(Object? request);

/// Settings for the tracking script. Every setting is optional except the
/// site id.
///
/// Set them once with [PrivatusConfig.global], or pass a config to each call.
class PrivatusConfig {
  /// The origin that serves `/js/pa.js` when none is set.
  static const String defaultHost = 'https://privatusstats.com';

  /// The tracker modules you can load.
  static const List<String> moduleNames = [
    'engage',
    'auto',
    'vitals',
    'clicks',
    'ask',
  ];

  /// The single-page app modes the tracker knows.
  static const List<String> spaModes = ['auto', 'history', 'hash', 'off'];

  /// Environment variables read, in order, to find the current environment.
  static const List<String> environmentVariables = [
    'PRIVATUS_ENV',
    'APP_ENV',
    'DART_ENV',
  ];

  /// The settings used when a call gets no config. Starts with every default.
  static PrivatusConfig global = const PrivatusConfig();

  /// Creates a config. See each field for what it does.
  const PrivatusConfig({
    this.siteId,
    this.scriptHost,
    this.modules,
    this.excludedPaths = const [],
    this.domains,
    this.spa,
    this.manual = false,
    this.enabled,
    this.enabledEnvironments = const ['production'],
    this.environment,
    this.extraAttributes = const {},
    this.props = const {},
    this.propsBuilder,
    this.queueStub = false,
  });

  /// The site id (it starts with `pa_`). Falls back to the
  /// `PRIVATUS_SITE_ID` environment variable. Nothing prints without it.
  final String? siteId;

  /// The origin that serves `/js/pa.js`. Falls back to the
  /// `PRIVATUS_SCRIPT_HOST` environment variable, then [defaultHost].
  final String? scriptHost;

  /// Tracker modules to load, for example `['engage', 'auto']`. Null keeps the
  /// tracker default. An empty list loads none.
  final List<String>? modules;

  /// Path globs the tracker never counts, for example `['/admin/*']`.
  final List<String> excludedPaths;

  /// Hostnames to count. Null counts every host.
  final List<String>? domains;

  /// One of `auto`, `history`, `hash` or `off`. Null keeps the tracker default.
  final String? spa;

  /// True turns off the automatic pageview.
  final bool manual;

  /// True or false forces the tag on or off in every environment. Null uses
  /// [enabledEnvironments].
  final bool? enabled;

  /// Environments that get the tag. Used when [enabled] is null.
  final List<String> enabledEnvironments;

  /// The current environment. Null reads `PRIVATUS_ENV`, `APP_ENV` and
  /// `DART_ENV`, and when none is set uses `production` for compiled release
  /// builds (`dart compile`, `flutter build web`) and `development` otherwise.
  final String? environment;

  /// Other attributes for the script tag, for example
  /// `{'data-mask': '/orders/*->/orders/:id'}`. A `true` value prints the
  /// name only. Null values are left out.
  final Map<String, Object?> extraAttributes;

  /// Page props sent with every pageview and event, for example
  /// `{'plan': 'pro'}`. Never put names, emails or user ids here.
  final Map<String, Object?> props;

  /// Builds page props for each request. Its result is merged over [props].
  final PagePropsBuilder? propsBuilder;

  /// True prints the tracker's queue stub first, so `privatus.track` calls
  /// made before the tracker loads are kept and sent later.
  final bool queueStub;

  /// The site id to use, or null when there is none.
  String? get resolvedSiteId {
    final value = siteId?.trim() ?? '';
    if (value.isNotEmpty) return value;
    return readEnvironment('PRIVATUS_SITE_ID');
  }

  /// The script host to use, without a trailing slash.
  String get resolvedScriptHost {
    var value = scriptHost?.trim() ?? '';
    if (value.isEmpty) value = readEnvironment('PRIVATUS_SCRIPT_HOST') ?? '';
    if (value.isEmpty) value = defaultHost;
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  /// The environment to use. See [environment].
  String get resolvedEnvironment {
    final value = environment?.trim() ?? '';
    if (value.isNotEmpty) return value;
    for (final name in environmentVariables) {
      final found = readEnvironment(name);
      if (found != null) return found;
    }
    return const bool.fromEnvironment('dart.vm.product')
        ? 'production'
        : 'development';
  }

  /// Whether the tag prints in [environmentName] (default: the current one).
  bool isEnabled([String? environmentName]) {
    if (enabled != null) return enabled!;
    final current = (environmentName ?? resolvedEnvironment).toLowerCase();
    return enabledEnvironments.any((name) => name.toLowerCase() == current);
  }

  /// The configured props for one request: [props] with the result of
  /// [propsBuilder] merged on top.
  Map<String, Object?> pageProps([Object? request]) {
    final built = propsBuilder?.call(request);
    return {...props, if (built != null) ...built};
  }

  /// A copy with some settings changed. A null argument keeps the current
  /// value.
  PrivatusConfig copyWith({
    String? siteId,
    String? scriptHost,
    List<String>? modules,
    List<String>? excludedPaths,
    List<String>? domains,
    String? spa,
    bool? manual,
    bool? enabled,
    List<String>? enabledEnvironments,
    String? environment,
    Map<String, Object?>? extraAttributes,
    Map<String, Object?>? props,
    PagePropsBuilder? propsBuilder,
    bool? queueStub,
  }) {
    return PrivatusConfig(
      siteId: siteId ?? this.siteId,
      scriptHost: scriptHost ?? this.scriptHost,
      modules: modules ?? this.modules,
      excludedPaths: excludedPaths ?? this.excludedPaths,
      domains: domains ?? this.domains,
      spa: spa ?? this.spa,
      manual: manual ?? this.manual,
      enabled: enabled ?? this.enabled,
      enabledEnvironments: enabledEnvironments ?? this.enabledEnvironments,
      environment: environment ?? this.environment,
      extraAttributes: extraAttributes ?? this.extraAttributes,
      props: props ?? this.props,
      propsBuilder: propsBuilder ?? this.propsBuilder,
      queueStub: queueStub ?? this.queueStub,
    );
  }
}
