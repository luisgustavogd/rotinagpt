import 'meal_entry.dart';

abstract class MealRepository {
  /// RF-024 — inclui um intervalo amplo o bastante para permitir "duplicar
  /// refeição anterior" sem paginação adicional na maioria dos casos de uso.
  Stream<List<MealEntry>> watchRange(DateTime from, DateTime to);

  Future<void> save(MealEntry meal);

  Future<void> delete(String mealId);
}
