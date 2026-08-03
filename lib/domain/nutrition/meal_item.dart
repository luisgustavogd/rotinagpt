import 'meal_unit.dart';

/// Item de uma refeição. Guarda um "snapshot" do alimento (nome, proteína e
/// calorias já calculadas para a quantidade informada) para que editar ou
/// excluir um [Food] depois nunca altere o histórico já registrado.
class MealItem {
  const MealItem({
    required this.foodId,
    required this.foodNameSnapshot,
    required this.quantity,
    required this.unit,
    required this.proteinG,
    this.caloriesKcal,
  });

  final String foodId;
  final String foodNameSnapshot;
  final double quantity;
  final MealUnit unit;
  final double proteinG;
  final double? caloriesKcal;
}
