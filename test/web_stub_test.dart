import 'package:privatus_analytics/web.dart';
import 'package:test/test.dart';

void main() {
  test('injectTracker and track do nothing off the web', () {
    expect(
      injectTracker(
        config: const PrivatusConfig(siteId: 'pa_TEST123456', enabled: true),
      ),
      isFalse,
    );
    expect(track('Report exported', {'format': 'csv'}), isFalse);
  });

  test('the web library also exports the core functions', () {
    expect(clickAttr('pricing.cta'), 'data-privatus-click="pricing.cta"');
  });
}
