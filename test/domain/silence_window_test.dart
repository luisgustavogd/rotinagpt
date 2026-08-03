import 'package:flutter_test/flutter_test.dart';
import 'package:rotinagpt/domain/notifications/silence_window.dart';

void main() {
  test('RF-062: janela que não cruza a meia-noite', () {
    const window = SilenceWindow(start: '13:00', end: '14:00');
    expect(window.contains(DateTime(2026, 8, 3, 13, 30)), isTrue);
    expect(window.contains(DateTime(2026, 8, 3, 12, 59)), isFalse);
  });

  test('RF-062: janela que cruza a meia-noite (silêncio noturno)', () {
    const window = SilenceWindow(start: '22:00', end: '06:00');
    expect(window.contains(DateTime(2026, 8, 3, 23, 0)), isTrue);
    expect(window.contains(DateTime(2026, 8, 3, 5, 30)), isTrue);
    expect(window.contains(DateTime(2026, 8, 3, 12, 0)), isFalse);
  });
}
