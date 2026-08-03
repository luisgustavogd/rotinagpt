import 'package:flutter_test/flutter_test.dart';
import 'package:rotinagpt/domain/profile/goal_history_entry.dart';

void main() {
  test('RN-008: meta alterada vale a partir da data da mudança', () {
    final history = [
      GoalHistoryEntry(
        id: '1',
        kind: GoalKind.protein,
        value: 100,
        effectiveDate: DateTime(2026, 1, 1),
      ),
      GoalHistoryEntry(
        id: '2',
        kind: GoalKind.protein,
        value: 130,
        effectiveDate: DateTime(2026, 6, 1),
      ),
    ];

    expect(
      GoalHistoryEntry.valueAt(history, GoalKind.protein, DateTime(2026, 3, 1)),
      100,
    );
    expect(
      GoalHistoryEntry.valueAt(history, GoalKind.protein, DateTime(2026, 7, 1)),
      130,
    );
    expect(
      GoalHistoryEntry.valueAt(history, GoalKind.weight, DateTime(2026, 7, 1)),
      isNull,
    );
  });
}
