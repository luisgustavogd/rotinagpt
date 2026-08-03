import 'food.dart';

abstract class FoodRepository {
  Stream<List<Food>> watchAll();

  Future<void> save(Food food);

  Future<void> delete(String foodId);
}
