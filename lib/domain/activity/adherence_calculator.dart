import 'activity_entry.dart';

class WeeklyAdherence {
  const WeeklyAdherence({
    required this.completed,
    required this.partial,
    required this.notDone,
    required this.totalMinutes,
  });

  final int completed;
  final int partial;
  final int notDone;
  final int totalMinutes;

  int get plannedCount => completed + partial + notDone;
}

/// RF-081/RN-007 — resumo semanal de adesão, distinguindo sessões parciais
/// de completas (nunca soma as duas como se fossem equivalentes).
class AdherenceCalculator {
  const AdherenceCalculator();

  WeeklyAdherence weeklyAdherence(
    List<ActivityEntry> entries,
    DateTime weekStart,
  ) {
    final weekEnd = weekStart.add(const Duration(days: 7));
    final inWeek = entries.where((e) {
      return !e.dateTime.isBefore(weekStart) && e.dateTime.isBefore(weekEnd);
    });

    var completed = 0;
    var partial = 0;
    var notDone = 0;
    var minutes = 0;
    for (final e in inWeek) {
      switch (e.status) {
        case ActivityStatus.completed:
          completed++;
          minutes += e.durationMin;
        case ActivityStatus.partial:
          partial++;
          minutes += e.durationMin;
        case ActivityStatus.notDone:
          notDone++;
      }
    }
    return WeeklyAdherence(
      completed: completed,
      partial: partial,
      notDone: notDone,
      totalMinutes: minutes,
    );
  }
}
