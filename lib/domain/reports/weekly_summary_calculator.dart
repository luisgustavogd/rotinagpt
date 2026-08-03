import '../activity/activity_entry.dart';
import '../activity/adherence_calculator.dart';
import '../measurements/weight_entry.dart';
import '../nutrition/meal_entry.dart';
import '../nutrition/protein_calculator.dart';
import 'weekly_summary.dart';

class WeeklySummaryCalculator {
  const WeeklySummaryCalculator({
    this.proteinCalculator = const ProteinCalculator(),
    this.adherenceCalculator = const AdherenceCalculator(),
  });

  final ProteinCalculator proteinCalculator;
  final AdherenceCalculator adherenceCalculator;

  WeeklySummary build({
    required DateTime weekStart,
    required List<MealEntry> meals,
    required List<WeightEntry> weights,
    required List<ActivityEntry> activities,
  }) {
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));

    var proteinSum = 0.0;
    var daysWithMeals = 0;
    for (final day in days) {
      final protein = proteinCalculator.consumedProteinForDay(meals, day);
      if (protein > 0) daysWithMeals++;
      proteinSum += protein;
    }
    final averageProtein = proteinSum / 7;

    final weekEnd = weekStart.add(const Duration(days: 7));
    final weekWeights = weights.where((w) {
      return !w.dateTime.isBefore(weekStart) && w.dateTime.isBefore(weekEnd);
    }).toList()..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final weightVariation = weekWeights.length >= 2
        ? weekWeights.last.weightKg - weekWeights.first.weightKg
        : null;

    final adherence = adherenceCalculator.weeklyAdherence(
      activities,
      weekStart,
    );

    return WeeklySummary(
      weekStart: weekStart,
      averageProteinG: averageProtein,
      weightVariationKg: weightVariation,
      activityMinutes: adherence.totalMinutes,
      completedActivities: adherence.completed,
      partialActivities: adherence.partial,
      daysWithMealsConfirmed: daysWithMeals,
    );
  }
}
