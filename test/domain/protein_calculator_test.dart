import 'package:flutter_test/flutter_test.dart';
import 'package:rotinagpt/domain/nutrition/meal_entry.dart';
import 'package:rotinagpt/domain/nutrition/meal_item.dart';
import 'package:rotinagpt/domain/nutrition/meal_unit.dart';
import 'package:rotinagpt/domain/nutrition/protein_calculator.dart';

MealItem _item(double protein) => MealItem(
  foodId: 'f1',
  foodNameSnapshot: 'Ovo',
  quantity: 100,
  unit: MealUnit.grams,
  proteinG: protein,
);

void main() {
  final calculator = ProteinCalculator();
  final day = DateTime(2026, 8, 3);

  test('RN-001: soma só refeições confirmadas do dia', () {
    final meals = [
      MealEntry(
        id: '1',
        dateTime: DateTime(2026, 8, 3, 8),
        mealType: MealType.breakfast,
        items: [_item(20)],
        status: MealStatus.confirmed,
      ),
      MealEntry(
        id: '2',
        dateTime: DateTime(2026, 8, 3, 12),
        mealType: MealType.lunch,
        items: [_item(30)],
        status: MealStatus.planned, // não confirmada: não deve contar
      ),
      MealEntry(
        id: '3',
        dateTime: DateTime(2026, 8, 2, 20), // outro dia: não deve contar
        mealType: MealType.dinner,
        items: [_item(50)],
        status: MealStatus.confirmed,
      ),
    ];

    expect(calculator.consumedProteinForDay(meals, day), 20);
  });

  test('RF-011: proteína restante nunca é negativa', () {
    expect(
      calculator.remainingProtein(targetProteinG: 100, consumedProteinG: 130),
      0,
    );
    expect(
      calculator.remainingProtein(targetProteinG: 100, consumedProteinG: 40),
      60,
    );
  });

  test('RF-011: percentual de progresso pode ultrapassar 100', () {
    expect(
      calculator.progressPercent(targetProteinG: 100, consumedProteinG: 120),
      120,
    );
  });

  test(
    'RF-027: soma de calorias é nula se algum item não informar calorias',
    () {
      final meal = MealEntry(
        id: '1',
        dateTime: day,
        mealType: MealType.breakfast,
        items: [_item(20)], // sem caloriesKcal
        status: MealStatus.confirmed,
      );
      expect(meal.totalCaloriesKcal, isNull);
    },
  );
}
