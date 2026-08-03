import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/nutrition/meal_entry.dart';
import '../../../domain/nutrition/meal_repository.dart';
import '../firestore_paths.dart';
import '../mappers/meal_mapper.dart';

class MealRepositoryImpl implements MealRepository {
  MealRepositoryImpl(this._firestore, this._paths);

  final FirebaseFirestore _firestore;
  final FirestorePaths _paths;

  @override
  Stream<List<MealEntry>> watchRange(DateTime from, DateTime to) {
    return _firestore
        .collection(_paths.meals)
        .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('dateTime', isLessThan: Timestamp.fromDate(to))
        .orderBy('dateTime')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => MealMapper.fromMap(d.id, d.data())).toList(),
        );
  }

  @override
  Future<void> save(MealEntry meal) {
    return _firestore
        .collection(_paths.meals)
        .doc(meal.id)
        .set(MealMapper.toMap(meal));
  }

  @override
  Future<void> delete(String mealId) {
    return _firestore.collection(_paths.meals).doc(mealId).delete();
  }
}
