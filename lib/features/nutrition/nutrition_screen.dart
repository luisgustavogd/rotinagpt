import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/nutrition/food.dart';
import '../../domain/nutrition/meal_entry.dart';
import '../../domain/nutrition/meal_item.dart';
import '../../domain/nutrition/meal_unit.dart';

final _foodsProvider = StreamProvider.autoDispose((ref) {
  return ref.watch(foodRepositoryProvider).watchAll();
});

DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

final _todayMealsProvider = StreamProvider.autoDispose((ref) {
  final today = _startOfDay(DateTime.now());
  return ref
      .watch(mealRepositoryProvider)
      .watchRange(today, today.add(const Duration(days: 1)));
});

String _unitLabel(MealUnit unit) => switch (unit) {
  MealUnit.grams => 'g',
  MealUnit.milliliters => 'ml',
  MealUnit.unit => 'un',
  MealUnit.spoon => 'colher',
  MealUnit.ladle => 'concha',
  MealUnit.slice => 'fatia',
  MealUnit.scoop => 'scoop',
  MealUnit.portion => 'porção',
};

/// RF-020 a RF-029 — refeições do dia, favoritos, alimentos e metas.
class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Alimentação'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Hoje'),
              Tab(text: 'Alimentos'),
            ],
          ),
        ),
        body: const TabBarView(children: [_TodayMealsTab(), _FoodsTab()]),
      ),
    );
  }
}

class _TodayMealsTab extends ConsumerWidget {
  const _TodayMealsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealsAsync = ref.watch(_todayMealsProvider);
    final foodsAsync = ref.watch(_foodsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            _registerMeal(context, ref, foodsAsync.valueOrNull ?? []),
        child: const Icon(Icons.add),
      ),
      body: mealsAsync.when(
        data: (meals) {
          if (meals.isEmpty) {
            return const Center(
              child: Text('Nenhuma refeição registrada hoje ainda.'),
            );
          }
          return ListView(
            children: [
              for (final meal in meals)
                ListTile(
                  title: Text(
                    meal.items.map((i) => i.foodNameSnapshot).join(', '),
                  ),
                  subtitle: Text(
                    '${meal.totalProteinG.toStringAsFixed(1)}g proteína · '
                    '${meal.status == MealStatus.confirmed
                        ? 'Confirmada'
                        : meal.status == MealStatus.planned
                        ? 'Planejada'
                        : 'Não realizada'}',
                  ),
                  trailing: meal.status != MealStatus.confirmed
                      ? IconButton(
                          icon: const Icon(Icons.check_circle_outline),
                          onPressed: () => ref
                              .read(mealRepositoryProvider)
                              .save(
                                meal.copyWith(status: MealStatus.confirmed),
                              ),
                        )
                      : const Icon(Icons.check_circle, color: Colors.green),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
    );
  }

  Future<void> _registerMeal(
    BuildContext context,
    WidgetRef ref,
    List<Food> foods,
  ) async {
    if (foods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastre um alimento primeiro, na aba Alimentos.'),
        ),
      );
      return;
    }

    var selected = foods.first;
    final quantityController = TextEditingController(
      text: selected.defaultPortion.toString(),
    );
    var mealType = MealType.breakfast;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<MealType>(
                initialValue: mealType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de refeição',
                ),
                items: const [
                  DropdownMenuItem(
                    value: MealType.breakfast,
                    child: Text('Café da manhã'),
                  ),
                  DropdownMenuItem(
                    value: MealType.lunch,
                    child: Text('Almoço'),
                  ),
                  DropdownMenuItem(
                    value: MealType.snack,
                    child: Text('Lanche'),
                  ),
                  DropdownMenuItem(
                    value: MealType.dinner,
                    child: Text('Jantar'),
                  ),
                  DropdownMenuItem(value: MealType.other, child: Text('Outra')),
                ],
                onChanged: (v) => setState(() => mealType = v!),
              ),
              DropdownButtonFormField<Food>(
                initialValue: selected,
                decoration: const InputDecoration(labelText: 'Alimento'),
                items: [
                  for (final f in foods)
                    DropdownMenuItem(value: f, child: Text(f.name)),
                ],
                onChanged: (v) => setState(() {
                  selected = v!;
                  quantityController.text = selected.defaultPortion.toString();
                }),
              ),
              TextField(
                controller: quantityController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Quantidade (${_unitLabel(selected.unit)})',
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Registrar e confirmar'),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;
    final quantity =
        double.tryParse(quantityController.text.replaceAll(',', '.')) ??
        selected.defaultPortion;

    final now = DateTime.now();
    await ref
        .read(mealRepositoryProvider)
        .save(
          MealEntry(
            id: now.microsecondsSinceEpoch.toString(),
            dateTime: now,
            mealType: mealType,
            status: MealStatus.confirmed,
            items: [
              MealItem(
                foodId: selected.id,
                foodNameSnapshot: selected.name,
                quantity: quantity,
                unit: selected.unit,
                proteinG: selected.proteinFor(quantity),
                caloriesKcal: selected.caloriesFor(quantity),
              ),
            ],
          ),
        );
  }
}

class _FoodsTab extends ConsumerWidget {
  const _FoodsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foodsAsync = ref.watch(_foodsProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _editFood(context, ref),
        child: const Icon(Icons.add),
      ),
      body: foodsAsync.when(
        data: (foods) => foods.isEmpty
            ? const Center(child: Text('Nenhum alimento cadastrado ainda.'))
            : ListView(
                children: [
                  for (final food in foods)
                    ListTile(
                      title: Text(food.name),
                      subtitle: Text(
                        '${food.proteinG}g proteína / ${food.defaultPortion} ${_unitLabel(food.unit)}',
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          food.favorite ? Icons.star : Icons.star_border,
                          color: food.favorite ? Colors.amber : null,
                        ),
                        onPressed: () => ref
                            .read(foodRepositoryProvider)
                            .save(food.copyWith(favorite: !food.favorite)),
                      ),
                    ),
                ],
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
    );
  }

  Future<void> _editFood(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final portionController = TextEditingController(text: '100');
    final proteinController = TextEditingController();
    final caloriesController = TextEditingController();
    var unit = MealUnit.grams;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome do alimento',
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: portionController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Porção padrão',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<MealUnit>(
                      initialValue: unit,
                      decoration: const InputDecoration(labelText: 'Unidade'),
                      items: [
                        for (final u in MealUnit.values)
                          DropdownMenuItem(
                            value: u,
                            child: Text(_unitLabel(u)),
                          ),
                      ],
                      onChanged: (v) => setState(() => unit = v!),
                    ),
                  ),
                ],
              ),
              TextField(
                controller: proteinController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Proteína (g) na porção padrão',
                ),
              ),
              TextField(
                controller: caloriesController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Calorias (kcal, opcional)',
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );

    final portion = double.tryParse(
      portionController.text.replaceAll(',', '.'),
    );
    final protein = double.tryParse(
      proteinController.text.replaceAll(',', '.'),
    );
    if (saved == true &&
        nameController.text.trim().isNotEmpty &&
        portion != null &&
        protein != null) {
      await ref
          .read(foodRepositoryProvider)
          .save(
            Food(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              name: nameController.text.trim(),
              defaultPortion: portion,
              unit: unit,
              proteinG: protein,
              caloriesKcal: double.tryParse(
                caloriesController.text.replaceAll(',', '.'),
              ),
            ),
          );
    }
  }
}
