import 'dart:convert';

import 'package:privatus_analytics/privatus_analytics.dart';
import 'package:test/test.dart';

void main() {
  test('props become a JSON object', () {
    expect(pagePropsJson({'plan': 'pro', 'role': 'admin'}),
        '{"plan":"pro","role":"admin"}');
  });

  test('empty props give null', () {
    expect(pagePropsJson({}), isNull);
    expect(pagePropsJson(null), isNull);
    expect(pagePropsJson({'gone': null}), isNull);
  });

  test('numbers, booleans and lists keep their JSON types', () {
    expect(
      pagePropsJson({
        'seats': 5,
        'ratio': 1.5,
        'beta': true,
        'old': false,
        'flags': ['a', null, 'b', 3],
        'bad': double.nan,
      }),
      '{"seats":5,"ratio":1.5,"beta":true,"old":false,"flags":["a","b",3]}',
    );
  });

  test('keys are cleaned like event props', () {
    expect(pagePropsJson({'App Version': '2.1'}), '{"app_version":"2.1"}');
  });

  test('limits props, list items and value length', () {
    final many = {for (var i = 1; i <= 40; i++) 'p$i': i};
    Map<String, Object?> parse(String? json) =>
        jsonDecode(json!) as Map<String, Object?>;

    expect(parse(pagePropsJson(many)), hasLength(30));
    expect(
      parse(pagePropsJson({
        'list': [for (var i = 1; i <= 50; i++) '$i'],
      }))['list'],
      hasLength(30),
    );
    expect(parse(pagePropsJson({'long': 'x' * 900}))['long'], hasLength(500));
  });

  test('the JSON is safe inside a script tag', () {
    final json = pagePropsJson({'note': '</script><b>&\u2028\u2029'})!;
    expect(
      json,
      r'{"note":"\u003c/script\u003e\u003cb\u003e\u0026\u2028\u2029"}',
    );
    expect(json, isNot(matches(RegExp('[<>&\u2028\u2029]'))));
    expect((jsonDecode(json) as Map)['note'], '</script><b>&\u2028\u2029');
  });
}
