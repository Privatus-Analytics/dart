# Changelog

## 1.0.0 - 2026-10-25

- Initial release.
- `tag()` builds the Privatus Analytics script tag, with `PrivatusConfig` for
  the site id, script host, modules, excluded paths, domains, single-page app
  mode, manual mode, extra attributes and the Content Security Policy nonce.
- Prints the tag only in production by default (`PRIVATUS_ENV`, `APP_ENV`,
  `DART_ENV`, or compiled release builds).
- `eventAttrs` and `eventData` for custom events on buttons, links and forms.
- `clickAttr` and `clickData` for click map names.
- Page props (`props`, `propsBuilder`, `tag(props: ...)`) print the
  `privatusPageProps` script and `data-props`. `pagePropsJson` gives the JSON.
- `queueStub` setting, so `privatus.track` calls made before the tracker loads
  are kept.
- `privatusMiddleware()` for shelf adds the tag to the head of HTML responses.
- `injectTracker()` and `track()` for Flutter web and other Dart web apps.
  They do nothing off the web.
