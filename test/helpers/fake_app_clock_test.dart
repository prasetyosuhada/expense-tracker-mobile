import 'package:flutter_test/flutter_test.dart';

import 'package:expensetracker/core/clock/app_clock.dart';

import 'fake_app_clock.dart';

void main() {
  test('FakeAppClock returns a fixed time until the test changes it', () {
    final initial = DateTime(2026, 9, 8, 23, 59);
    final later = DateTime.utc(2026, 9, 9);
    final AppClock clock = FakeAppClock(initial);
    expect(clock.now(), same(initial));
    expect(clock.now(), same(initial));

    (clock as FakeAppClock).currentTime = later;
    expect(clock.now(), same(later));
    expect(clock.now(), same(later));
  });
}
