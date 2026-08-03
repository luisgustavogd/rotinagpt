import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/nutrition/food.dart';
import '../../../domain/nutrition/food_repository.dart';
import '../firestore_paths.dart';
import '../mappers/food_mapper.dart';

class FoodRepositoryImpl implements FoodRepository {
  FoodRepositoryImpl(this._firestore, this._paths);

  final FirebaseFirestore _firestore;
  final FirestorePaths _paths;

  @override
  Stream<List<Food>> watchAll() {
    return _firestore
        .collection(_paths.foods)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => FoodMapper.fromMap(d.id, d.data())).toList(),
        );
  }

  @override
  Future<void> save(Food food) {
    return _firestore
        .collection(_paths.foods)
        .doc(food.id)
        .set(FoodMapper.toMap(food));
  }

  @override
  Future<void> delete(String foodId) {
    return _firestore.collection(_paths.foods).doc(foodId).delete();
  }
}
