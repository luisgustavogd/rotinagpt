import 'package:flutter_test/flutter_test.dart';
import 'package:rotinagpt/domain/activity/activity_entry.dart';
import 'package:rotinagpt/domain/activity/activity_type.dart';
import 'package:rotinagpt/domain/activity/adherence_calculator.dart';

void main() {
  test('RN-007: distingue atividade parcial de completa no resumo semanal', () {
    final weekStart = DateTime(2026, 8, 3); // segunda-feira
    final entries = [
      ActivityEntry(
        id: '1',
        dateTime: DateTime(2026, 8, 3, 7),
        type: ActivityType.bike,
        durationMin: 40,
        perceivedEffort: 5,
        status: ActivityStatus.completed,
      ),
      ActivityEntry(
        id: '2',
        dateTime: DateTime(2026, 8, 4, 7),
        type: ActivityType.walk,
        durationMin: 15,
        perceivedEffort: 3,
        status: ActivityStatus.partial,
      ),
      ActivityEntry(
        id: '3',
        dateTime: DateTime(2026, 8, 5, 7),
        type: ActivityType.strength,
        durationMin: 30,
        perceivedEffort: 6,
        status: ActivityStatus.notDone,
      ),
    ];

    final adherence = const AdherenceCalculator().weeklyAdherence(
      entries,
      weekStart,
    );

    expect(adherence.completed, 1);
    expect(adherence.partial, 1);
    expect(adherence.notDone, 1);
    expect(adherence.totalMinutes, 55); // só completed+partial contam minutos
  });
}
