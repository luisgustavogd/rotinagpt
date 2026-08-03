import 'package:flutter_test/flutter_test.dart';
import 'package:rotinagpt/domain/activity/activity_entry.dart';
import 'package:rotinagpt/domain/activity/activity_type.dart';
import 'package:rotinagpt/domain/measurements/weight_entry.dart';
import 'package:rotinagpt/domain/nutrition/meal_entry.dart';
import 'package:rotinagpt/domain/nutrition/meal_item.dart';
import 'package:rotinagpt/domain/nutrition/meal_unit.dart';
import 'package:rotinagpt/domain/reports/weekly_summary_calculator.dart';

void main() {
  test('RF-081: resumo semanal combina proteína, peso e adesão', () {
    final weekStart = DateTime(2026, 8, 3); // segunda-feira

    final meals = [
      MealEntry(
        id: '1',
        dateTime: DateTime(2026, 8, 3, 8),
        mealType: MealType.breakfast,
        status: MealStatus.confirmed,
        items: const [
          MealItem(
            foodId: 'f1',
            foodNameSnapshot: 'Ovo',
            quantity: 100,
            unit: MealUnit.grams,
            proteinG: 20,
          ),
        ],
      ),
    ];
    final weights = [
      WeightEntry(id: 'w1', dateTime: DateTime(2026, 8, 3), weightKg: 90),
      WeightEntry(id: 'w2', dateTime: DateTime(2026, 8, 9), weightKg: 89),
    ];
    final activities = [
      ActivityEntry(
        id: 'a1',
        dateTime: DateTime(2026, 8, 4),
        type: ActivityType.bike,
        durationMin: 40,
        perceivedEffort: 5,
        status: ActivityStatus.completed,
      ),
    ];

    final summary = const WeeklySummaryCalculator().build(
      weekStart: weekStart,
      meals: meals,
      weights: weights,
      activities: activities,
    );

    expect(summary.averageProteinG, closeTo(20 / 7, 0.001));
    expect(summary.weightVariationKg, -1);
    expect(summary.activityMinutes, 40);
    expect(summary.completedActivities, 1);
    expect(summary.daysWithMealsConfirmed, 1);
  });
}
