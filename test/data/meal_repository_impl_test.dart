import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rotinagpt/data/remote/firestore_paths.dart';
import 'package:rotinagpt/data/remote/repositories/meal_repository_impl.dart';
import 'package:rotinagpt/domain/nutrition/meal_entry.dart';
import 'package:rotinagpt/domain/nutrition/meal_item.dart';
import 'package:rotinagpt/domain/nutrition/meal_unit.dart';
import 'package:rotinagpt/domain/nutrition/protein_calculator.dart';

void main() {
  test(
    'grava e lê refeições por intervalo, preservando itens e status',
    () async {
      final firestore = FakeFirebaseFirestore();
      final repo = MealRepositoryImpl(
        firestore,
        const FirestorePaths('user-1'),
      );

      final meal = MealEntry(
        id: 'm1',
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
      );
      await repo.save(meal);

      final loaded = await repo
          .watchRange(DateTime(2026, 8, 3), DateTime(2026, 8, 4))
          .first;

      expect(loaded, hasLength(1));
      expect(loaded.single.items.single.foodNameSnapshot, 'Ovo');
      expect(
        const ProteinCalculator().consumedProteinForDay(
          loaded,
          DateTime(2026, 8, 3),
        ),
        20,
      );
    },
  );

  test('refeições fora do intervalo não aparecem no watchRange', () async {
    final firestore = FakeFirebaseFirestore();
    final repo = MealRepositoryImpl(firestore, const FirestorePaths('user-1'));

    await repo.save(
      MealEntry(
        id: 'm1',
        dateTime: DateTime(2026, 8, 10),
        mealType: MealType.lunch,
        status: MealStatus.confirmed,
        items: const [],
      ),
    );

    final loaded = await repo
        .watchRange(DateTime(2026, 8, 3), DateTime(2026, 8, 4))
        .first;
    expect(loaded, isEmpty);
  });
}
