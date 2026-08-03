import '../../../domain/nutrition/food.dart';
import '../../../domain/nutrition/meal_unit.dart';

class FoodMapper {
  const FoodMapper._();

  static Map<String, dynamic> toMap(Food food) => {
    'name': food.name,
    'defaultPortion': food.defaultPortion,
    'unit': food.unit.name,
    'proteinG': food.proteinG,
    'caloriesKcal': food.caloriesKcal,
    'favorite': food.favorite,
  };

  static Food fromMap(String id, Map<String, dynamic> map) => Food(
    id: id,
    name: map['name'] as String,
    defaultPortion: (map['defaultPortion'] as num).toDouble(),
    unit: MealUnit.values.byName(map['unit'] as String),
    proteinG: (map['proteinG'] as num).toDouble(),
    caloriesKcal: (map['caloriesKcal'] as num?)?.toDouble(),
    favorite: map['favorite'] as bool? ?? false,
  );
}
