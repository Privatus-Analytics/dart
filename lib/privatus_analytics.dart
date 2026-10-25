/// Adds the cookieless Privatus Analytics tracking script to Dart websites.
///
/// The package only builds HTML: the browser script tag and data attributes.
/// It never sends events from your server, sets no cookies and reads no IP
/// addresses.
///
/// ```dart
/// import 'package:privatus_analytics/privatus_analytics.dart';
///
/// PrivatusConfig.global = const PrivatusConfig(siteId: 'pa_YOURSITEID');
/// final head = '<head>${tag()}</head>';
/// ```
library;

export 'src/attributes.dart'
    show
        attributesToHtml,
        clickAttr,
        clickData,
        eventAttrs,
        eventData,
        isValidClickName,
        maxEventName,
        maxPropKey,
        maxPropValue,
        maxProps,
        normalizeKey;
export 'src/config.dart' show PagePropsBuilder, PrivatusConfig;
export 'src/html.dart' show escapeHtml;
export 'src/page_props.dart' show maxListItems, pagePropsJson;
export 'src/tag.dart'
    show PrivatusTag, pagePropsFunction, queueStubScript, tag, trackerPath;
