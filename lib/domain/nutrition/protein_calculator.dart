import 'meal_entry.dart';

/// RN-001 — a proteína diária é a soma dos itens alimentares CONFIRMADOS no
/// dia (refeições planejadas não contam até serem confirmadas).
class ProteinCalculator {
  const ProteinCalculator();

  /// Proteína total (g) consumida em [day], considerando só refeições em
  /// [MealStatus.confirmed] cuja data cai no mesmo dia (ignora hora).
  double consumedProteinForDay(List<MealEntry> meals, DateTime day) {
    return _confirmedMealsForDay(
      meals,
      day,
    ).fold(0.0, (sum, m) => sum + m.totalProteinG);
  }

  /// RF-011 — proteína restante até a meta diária (nunca negativa).
  double remainingProtein({
    required double targetProteinG,
    required double consumedProteinG,
  }) {
    final remaining = targetProteinG - consumedProteinG;
    return remaining < 0 ? 0 : remaining;
  }

  /// RF-011 — percentual da meta já atingido (0-100+, sem cap superior para
  /// não esconder que a meta foi ultrapassada).
  double progressPercent({
    required double targetProteinG,
    required double consumedProteinG,
  }) {
    if (targetProteinG <= 0) return 0;
    return (consumedProteinG / targetProteinG) * 100;
  }

  List<MealEntry> _confirmedMealsForDay(List<MealEntry> meals, DateTime day) {
    return meals.where((m) {
      final d = m.dateTime;
      return m.status == MealStatus.confirmed &&
          d.year == day.year &&
          d.month == day.month &&
          d.day == day.day;
    }).toList();
  }
}
