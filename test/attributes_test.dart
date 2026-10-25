import 'package:privatus_analytics/privatus_analytics.dart';
import 'package:test/test.dart';

void main() {
  group('eventData', () {
    test('an event becomes data attributes', () {
      expect(eventData('Export CSV', {'format': 'csv', 'source': 'toolbar'}), {
        'data-privatus-event': 'Export CSV',
        'data-privatus-prop-format': 'csv',
        'data-privatus-prop-source': 'toolbar',
      });
    });

    test('the name is trimmed and cut to 120 characters', () {
      expect(eventData('  Export CSV  ')['data-privatus-event'], 'Export CSV');
      expect(eventData('a' * 200)['data-privatus-event'], 'a' * 120);
    });

    test('an empty name gives nothing', () {
      expect(eventData('   ', {'format': 'csv'}), isEmpty);
      expect(eventData(null), isEmpty);
      expect(eventAttrs(''), '');
    });

    test('prop keys are lowercased, cleaned and cut to 64 characters', () {
      final attrs = eventData('Saved', {
        'Report Type': 'a',
        'x-y': 'b',
        'K' * 80: 'c',
        'café': 'd',
      });
      expect(attrs['data-privatus-prop-report_type'], 'a');
      expect(attrs['data-privatus-prop-x_y'], 'b');
      expect(attrs['data-privatus-prop-${'k' * 64}'], 'c');
      expect(attrs['data-privatus-prop-caf_'], 'd');
    });

    test('values become strings and null values are dropped', () {
      final attrs = eventData('Saved', {
        'on': true,
        'off': false,
        'count': 3,
        'ratio': 1.5,
        'tags': ['a', null, 'b'],
        'gone': null,
      });
      expect(
        ['on', 'off', 'count', 'ratio', 'tags']
            .map((key) => attrs['data-privatus-prop-$key']),
        ['true', 'false', '3', '1.5', 'a,b'],
      );
      expect(attrs.containsKey('data-privatus-prop-gone'), isFalse);
    });

    test('values are cut to 500 characters and at most 30 props are kept', () {
      final props = {for (var i = 1; i <= 40; i++) 'p$i': 'v'};
      expect(eventData('Saved', props).length, 31);
      expect(
        eventData('Saved', {'long': 'x' * 900})['data-privatus-prop-long'],
        hasLength(500),
      );
    });

    test('cutting never splits an emoji', () {
      final value =
          eventData('Saved', {'e': '😀' * 600})['data-privatus-prop-e']!;
      expect(value.runes.length, 500);
    });
  });

  test('eventAttrs escapes every value', () {
    expect(
      eventAttrs('Say "hi" <now>', {'note': "a&b'c"}),
      'data-privatus-event="Say &quot;hi&quot; &lt;now&gt;" '
      'data-privatus-prop-note="a&amp;b&#39;c"',
    );
  });

  test('eventAttrs prints the documented example', () {
    expect(
      eventAttrs('Export CSV', {'format': 'csv', 'source': 'toolbar'}),
      'data-privatus-event="Export CSV" data-privatus-prop-format="csv" '
      'data-privatus-prop-source="toolbar"',
    );
  });

  group('click names', () {
    test('a valid name becomes a data attribute', () {
      expect(clickData('pricing.cta'), {'data-privatus-click': 'pricing.cta'});
      expect(clickAttr('a-b_c:d.1'), 'data-privatus-click="a-b_c:d.1"');
      expect(isValidClickName('pricing.cta'), isTrue);
    });

    test('an invalid name gives nothing', () {
      for (final name in ['', 'has space', 'x' * 101, '<b>', null]) {
        expect(clickData(name), isEmpty, reason: '$name');
        expect(clickAttr(name), '');
        expect(isValidClickName(name), isFalse);
      }
    });
  });
}
