# Privatus Analytics for Dart

Adds the cookieless [Privatus Analytics](https://privatusanalytics.com)
tracking script to Dart websites. It works with any server that builds HTML,
has a [shelf](https://pub.dev/packages/shelf) middleware that puts the tag in
the `<head>` for you, works with [Jaspr](https://pub.dev/packages/jaspr), and
has a small helper for Flutter web.

Privatus Analytics counts visits, sources, pages and conversions without
cookies, local storage or fingerprinting, so analytics does not need a consent
banner by itself. Check with your own counsel for your country.

The package only builds HTML: the browser script tag and a few attributes. It
never sends events from your server and sets no cookies. You need a Privatus
Analytics account to see reports, and there is a free plan. Sign up at
https://privatusanalytics.com.

**Only websites are counted.** Flutter apps for phones, tablets and desktops
are not supported, because the tracker runs in a web browser.

## Requirements

* Dart 3.3 or later.
* A Privatus Analytics site id (it starts with `pa_`). You find it under
  Site settings, Tracking.

## Install

```sh
dart pub add privatus_analytics
```

For the full setup guide and every tracker option, see the [Privatus
Analytics docs](https://privatusanalytics.com/docs).

Set your site id with an environment variable:

```sh
PRIVATUS_SITE_ID=pa_YOURSITEID
```

or in code, once, when your app starts:

```dart
import 'package:privatus_analytics/privatus_analytics.dart';

void main() {
  PrivatusConfig.global = const PrivatusConfig(siteId: 'pa_YOURSITEID');
  // ...
}
```

In web builds (Flutter web, `dart compile js`) there are no environment
variables, so pass it at build time with
`--dart-define=PRIVATUS_SITE_ID=pa_YOURSITEID`, or set it in code.

## Add the tag

Put `tag()` in the `<head>` of your HTML:

```dart
final page = '''
<head>
  <title>My app</title>
  ${tag()}
</head>
''';
```

In production it prints:

```html
<script defer src="https://privatusstats.com/js/pa.js" data-site="pa_YOURSITEID"></script>
```

The tag prints nothing when there is no site id, and nothing outside
production (see below). If your site uses a Content Security Policy nonce,
pass it: `tag(nonce: nonce)`.

### Or let the middleware add it (shelf)

If your server uses shelf, add the middleware and you do not need to touch
your HTML:

```dart
import 'package:privatus_analytics/shelf.dart';
import 'package:shelf/shelf.dart';

final handler = const Pipeline()
    .addMiddleware(privatusMiddleware())
    .addHandler(app);
```

It adds the tag just before `</head>` in uncompressed `text/html` responses
with status 200, and sets the new `Content-Length`. It skips Ajax requests,
pages without a `<head>`, and pages that already have the tag. Responses that
carry a `Content-Encoding` header are left alone, so if you compress your
responses in shelf, put this middleware after the compression one in the
pipeline (so it runs first on the response), or use `tag()` instead.

For a Content Security Policy nonce, give the middleware a function, or put
the nonce in the request or response `context` under `privatusNonceKey`:

```dart
privatusMiddleware(nonce: (request) => request.context['csp.nonce'] as String?)
```

## Configuration

Every setting is optional except the site id.

```dart
PrivatusConfig.global = PrivatusConfig(
  siteId: 'pa_YOURSITEID',                  // or PRIVATUS_SITE_ID
  scriptHost: 'https://privatusstats.com',  // or PRIVATUS_SCRIPT_HOST
  modules: ['engage', 'auto', 'vitals', 'clicks', 'ask'],
  excludedPaths: ['/admin/*', '/preview/*'],
  domains: ['example.com', 'www.example.com'],
  spa: 'auto',          // auto, history, hash or off
  manual: false,        // true turns off the automatic pageview
  enabledEnvironments: ['production'],
  extraAttributes: {'data-mask': '/orders/*->/orders/:id'},
  propsBuilder: (request) => {'plan': planFor(request as Request)},
  queueStub: false,
);
```

| Setting | Default | What it does |
|---|---|---|
| `siteId` | `PRIVATUS_SITE_ID` | The `data-site` attribute. Nothing prints without it |
| `scriptHost` | `https://privatusstats.com` | Where `/js/pa.js` is served. Change it only if you host your own copy. Also read from `PRIVATUS_SCRIPT_HOST` |
| `modules` | tracker default (`engage`) | The `data-modules` attribute. Setting it replaces the default, so keep `engage` for time on page and scroll depth. `[]` loads none |
| `excludedPaths` | none | The `data-exclude` attribute. Path globs the tracker never counts |
| `domains` | all hosts | The `data-domains` attribute. Count only these hostnames |
| `spa` | `auto` | The `data-spa` attribute |
| `manual` | `false` | The `data-manual` attribute |
| `enabledEnvironments` | `['production']` | Environments that get the tag |
| `environment` | see below | The current environment |
| `enabled` | `null` | `true` or `false` forces the tag on or off in every environment |
| `extraAttributes` | `{}` | Any other `data-*` attribute. `true` prints the name only |
| `props` | `{}` | Page props sent with every pageview and event. See below |
| `propsBuilder` | `null` | A function that gets the request and returns more page props |
| `queueStub` | `false` | Prints a small script first, so `privatus.track` calls made before the tracker loads are kept and sent later |
| auto inject | off | Add `privatusMiddleware()` to your shelf pipeline |

Each tracker attribute is explained in the [script attributes
reference](https://privatusanalytics.com/docs/tracker/attributes), and the
modules in [Modules](https://privatusanalytics.com/docs/tracker/modules).

You can also pass a whole config, or override a setting, for one page:

```dart
tag(modules: ['engage', 'auto'], excludedPaths: ['/preview/*'])
tag(config: otherSiteConfig)
```

`PrivatusConfig` is immutable. `config.copyWith(spa: 'hash')` gives you a
changed copy.

### Development and test

The tag prints only in production by default, so your own clicking around
never reaches your reports. The package finds the environment like this:

1. the `environment` setting, if you set it;
2. else the first of the `PRIVATUS_ENV`, `APP_ENV` and `DART_ENV`
   environment variables that is set;
3. else `production` for compiled release builds (`dart compile exe`,
   `flutter build web`), and `development` for everything else, like
   `dart run` and `flutter run`.

So if you run your server with `dart run` in production, set
`PRIVATUS_ENV=production`. To see the tag while you build, set
`enabled: true`. The tracker also ignores `localhost` unless you pass
`data-allow-local` or `data-debug` (see [Debug
mode](https://privatusanalytics.com/docs/tracker/debug)):

```dart
const PrivatusConfig(enabled: true, extraAttributes: {'data-debug': 'true'})
```

### Leaving people out

Use `data-exclude` through `excludedPaths` for admin areas. To leave out
signed-in staff, print the tag only for other people:

```dart
'<head>${user?.isAdmin == true ? '' : tag()}</head>'
```

## Jaspr

The package does not depend on Jaspr, so you use the core functions with it.
`eventData` and `clickData` return attribute maps, which Jaspr elements take
as `attributes`. For the tag, print it as raw HTML in the head of your
document. For example, on the server:

```dart
import 'package:jaspr/jaspr.dart';
import 'package:privatus_analytics/privatus_analytics.dart';

Document(
  head: [raw(tag())],
  body: App(),
);

button(
  attributes: eventData('Report exported', {'format': 'csv'}),
  [text('Export')],
);

a(href: '/pricing', attributes: clickData('pricing.cta'), [text('See plans')]);
```

If your Jaspr site runs on your own shelf server, you can use
`privatusMiddleware()` instead of printing the tag.

## Flutter web

The simplest way is to paste the tag into `web/index.html`, inside `<head>`:

```html
<script defer src="https://privatusstats.com/js/pa.js" data-site="pa_YOURSITEID"></script>
```

That tag runs in every build, also while you develop. If you would rather
keep the site id out of the file and count only release builds, call
`injectTracker()` when your app starts. It adds the script to the page at
runtime:

```dart
import 'package:privatus_analytics/web.dart';

void main() {
  injectTracker(
    config: const PrivatusConfig(siteId: 'pa_YOURSITEID', spa: 'hash'),
  );
  runApp(const MyApp());
}
```

* It adds nothing in debug builds (`flutter run`), only in
  `flutter build web`. Use `enabled: true` to try it.
* It adds nothing when the page already loads `/js/pa.js`.
* It is safe to import in code that also runs on phones or on a server.
  There it does nothing and returns `false`.
* Flutter web uses URLs like `/#/settings` by default. Set `spa: 'hash'` so
  each screen counts as a page. If you switched to path URLs, leave `spa`
  out.

Flutter draws your app on a canvas, not with HTML buttons, so event
attributes and click map names do not work there. Send events from Dart
instead:

```dart
track('Report exported', {'format': 'csv'});
```

`track` calls the tracker's `privatus.track` in the browser. It follows the
same rules as event attributes, and returns `false` when the tracker is not
on the page. Set `queueStub: true` so calls made before the tracker loads are
kept.

## Product analytics: see which features people use

Privatus can show which buttons, forms and features people really use. You
add a few attributes to your HTML. The tracker reads them in the browser and
sends the events. Your server still sends nothing.

### Name events well

Use a short "Noun verb" name, like `Report exported` or `Invite sent`. Put the
details in props, not in the name. So write `Report exported` with
`{'format': 'csv'}`, not `Report exported as CSV`. Then all exports add up in
one place, and you can split them by format.

### Events on buttons, links and forms

`eventAttrs` prints the attributes inside a tag you write yourself:

```dart
'<button ${eventAttrs('Report exported', {'format': 'csv', 'source': 'toolbar'})}>Export</button>'
```

It prints:

```html
<button data-privatus-event="Report exported" data-privatus-prop-format="csv" data-privatus-prop-source="toolbar">Export</button>
```

`eventData` returns the same attributes as a map with full attribute names,
for code that takes an attributes map (like Jaspr components).

On a form, the event is sent when the form is submitted:

```dart
'<form action="/newsletter" method="post" ${eventAttrs('Newsletter joined', {'list': 'weekly'})}>'
```

The rules:

* The name is trimmed and cut to 120 characters. An empty name prints nothing.
* Prop keys are made lowercase. Anything that is not a letter, a digit or `_`
  becomes `_`, so `'Report Type'` becomes `report_type`. Keys are cut to 64
  characters.
* At most 30 props. Values become text: `true`, `false`, numbers as written,
  lists joined with commas. `null` values are left out. Values are cut to 500
  characters.
* Everything is escaped for HTML.
* The attributes print in every environment, even when the tag is off. They do
  nothing without the tracker, so your pages look the same in development and
  production.

### Click maps

A click map shows where people click on a page. Give the important parts a
name so they stay easy to find, even when the page changes:

```dart
'<a href="/pricing" ${clickAttr('pricing.cta')}>See plans</a>'
```

`clickData('pricing.cta')` gives the same as a map. A name may use letters,
digits and `_ . : -`, up to 100 characters. Anything else prints nothing, and
in debug mode the package writes a warning to the log.

### Page props: plan, role and other groups

Page props are sent with every pageview and event on the page. Use them to
split your reports by plan, role, app version, feature flag or account tier.

Set them for every page with `propsBuilder`. It runs for each page and gets
the request (in the shelf middleware, the shelf `Request`; with `tag()`,
whatever you pass as `request:`):

```dart
PrivatusConfig.global = PrivatusConfig(
  siteId: 'pa_YOURSITEID',
  props: const {'app_version': '2.4'},
  propsBuilder: (request) {
    final account = accountFor(request as Request);
    return {'plan': account?.plan, 'role': account?.role};
  },
);
```

A plain `props` map works too. You can also set or change props for one page.
They are merged over the configured ones, and `null` removes one:

```dart
tag(props: {'section': 'billing', 'role': null}, request: request)
```

The tag then prints a small script before the tracker, with your Content
Security Policy nonce when you pass one, and points the tracker at it:

```html
<script nonce="...">window.privatusPageProps=function(){return {"plan":"pro","role":"admin"}}</script>
<script defer src="https://privatusstats.com/js/pa.js" data-site="pa_YOURSITEID" data-props="privatusPageProps"></script>
```

Keys follow the same rules as event props. Numbers and true or false stay as
they are, and lists stay lists (up to 30 items). The props are escaped so they
are safe inside a script. `pagePropsJson(props)` gives you the JSON alone.

**Never put names, emails, user ids or anything that points to one person in
props.** Privatus counts visitors without any id. Put groups (like the plan or
the role), not people. The server also removes emails and long ids it finds.

### Track from your own JavaScript

For things that are not a click or a submit, call the tracker from your
JavaScript, as the [JavaScript API
docs](https://privatusanalytics.com/docs/tracker/javascript-api) explain:

```js
privatus.track("Feature used", { feature: "export" })
```

In Dart web code, `track('Feature used', {'feature': 'export'})` from
`package:privatus_analytics/web.dart` does the same.

If your code may run before the tracker has loaded, switch on the queue stub.
It prints a tiny script before the tracker that keeps your calls in a list and
sends them once the tracker is ready:

```dart
const PrivatusConfig(siteId: 'pa_YOURSITEID', queueStub: true)
```

or for one page: `tag(queueStub: true)`. The stub prints even when the tag is
off (in development, or with no site id). Then `tag()` prints only the stub,
with no tracker, so your `privatus.track(...)` calls never fail. They wait in
the list and are never sent.

### See the results

* [Funnels](https://privatusanalytics.com/docs/features/funnels): how many
  people go from one step to the next.
* [Click maps](https://privatusanalytics.com/docs/features/click-maps): where
  people click.
* [Goals](https://privatusanalytics.com/docs/features/goals): turn an event
  into a goal to count conversions.
* [Events](https://privatusanalytics.com/docs/events): every custom event and
  its props.

## Privacy

The script sets no cookies and stores nothing in the browser. The event, click
and props helpers only print HTML attributes and a small script. The package
makes no network requests and never reads IP addresses or browser details.
Keep people out of your props and event props: no names, emails or user ids.
See the [privacy documentation](https://privatusanalytics.com/docs/privacy)
for what is collected.

If you have a privacy policy, it should say which tools handle your visitors' data. You can paste this:

> This website uses [Privatus Analytics](https://privatusanalytics.com/privacy-analytics) to count visits. It
> does not use cookies and does not follow you from one website to another. Your IP address is used for a moment
> to count visits and is never stored.

Change it to fit your site. The [privacy policy generator](https://privatusanalytics.com/tools/privacy-policy-generator)
makes a longer version with your site's name in it.

## Development

The checks run in Docker so your local Dart does not matter:

```sh
./run-docker.sh
```

It runs `dart format`, `dart analyze --fatal-infos`, `dart test`, a web build
of the example, and `dart pub publish --dry-run` in the `dart:stable` image.

## Contributing

Bug reports and pull requests are welcome at
https://github.com/Privatus-Analytics/dart.

## License

MIT. See [LICENSE](LICENSE). Privatus Analytics is a product of Two Phase
LLC, Wyoming, USA.
