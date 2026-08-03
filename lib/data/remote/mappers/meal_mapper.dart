import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/nutrition/meal_entry.dart';
import '../../../domain/nutrition/meal_item.dart';
import '../../../domain/nutrition/meal_unit.dart';

class MealMapper {
  const MealMapper._();

  static Map<String, dynamic> toMap(MealEntry meal) => {
    'dateTime': Timestamp.fromDate(meal.dateTime),
    'mealType': meal.mealType.name,
    'status': meal.status.name,
    'items': meal.items.map(_itemToMap).toList(),
    'toleranceSymptoms': meal.toleranceSymptoms.map((s) => s.name).toList(),
    'observation': meal.observation,
  };

  static MealEntry fromMap(String id, Map<String, dynamic> map) => MealEntry(
    id: id,
    dateTime: (map['dateTime'] as Timestamp).toDate(),
    mealType: MealType.values.byName(map['mealType'] as String),
    status: MealStatus.values.byName(map['status'] as String),
    items: (map['items'] as List)
        .map((e) => _itemFromMap(Map<String, dynamic>.from(e as Map)))
        .toList(),
    toleranceSymptoms: (map['toleranceSymptoms'] as List? ?? [])
        .map((s) => ToleranceSymptom.values.byName(s as String))
        .toList(),
    observation: map['observation'] as String?,
  );

  static Map<String, dynamic> _itemToMap(MealItem item) => {
    'foodId': item.foodId,
    'foodNameSnapshot': item.foodNameSnapshot,
    'quantity': item.quantity,
    'unit': item.unit.name,
    'proteinG': item.proteinG,
    'caloriesKcal': item.caloriesKcal,
  };

  static MealItem _itemFromMap(Map<String, dynamic> map) => MealItem(
    foodId: map['foodId'] as String,
    foodNameSnapshot: map['foodNameSnapshot'] as String,
    quantity: (map['quantity'] as num).toDouble(),
    unit: MealUnit.values.byName(map['unit'] as String),
    proteinG: (map['proteinG'] as num).toDouble(),
    caloriesKcal: (map['caloriesKcal'] as num?)?.toDouble(),
  );
}
