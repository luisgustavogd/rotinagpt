import 'package:flutter_test/flutter_test.dart';
import 'package:rotinagpt/domain/medication/medication_duplicate_guard.dart';
import 'package:rotinagpt/domain/medication/medication_entry.dart';

void main() {
  const guard = MedicationDuplicateGuard();

  test(
    'RN-005: aplicação a poucos minutos de outra é sinalizada como possível duplicata',
    () {
      final existing = [
        MedicationEntry(
          id: '1',
          planId: 'p1',
          dateTime: DateTime(2026, 8, 3, 8, 0),
          dose: '5mg',
          applicationSite: 'Abdômen',
        ),
      ];

      expect(
        guard.isLikelyDuplicate(
          existingEntries: existing,
          planId: 'p1',
          candidateDateTime: DateTime(2026, 8, 3, 9, 30),
        ),
        isTrue,
      );
    },
  );

  test('aplicação de outro plano não é considerada duplicata', () {
    final existing = [
      MedicationEntry(
        id: '1',
        planId: 'p1',
        dateTime: DateTime(2026, 8, 3, 8, 0),
        dose: '5mg',
        applicationSite: 'Abdômen',
      ),
    ];

    expect(
      guard.isLikelyDuplicate(
        existingEntries: existing,
        planId: 'p2',
        candidateDateTime: DateTime(2026, 8, 3, 8, 30),
      ),
      isFalse,
    );
  });

  test('aplicação muito distante no tempo não é duplicata', () {
    final existing = [
      MedicationEntry(
        id: '1',
        planId: 'p1',
        dateTime: DateTime(2026, 8, 3, 8, 0),
        dose: '5mg',
        applicationSite: 'Abdômen',
      ),
    ];

    expect(
      guard.isLikelyDuplicate(
        existingEntries: existing,
        planId: 'p1',
        candidateDateTime: DateTime(2026, 8, 10, 8, 0),
      ),
      isFalse,
    );
  });
}
