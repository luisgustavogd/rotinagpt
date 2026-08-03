import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/measurements/body_measure_entry.dart';
import '../../../domain/measurements/measurement_repository.dart';
import '../../../domain/measurements/weight_entry.dart';
import '../firestore_paths.dart';
import '../mappers/measurement_mapper.dart';

class MeasurementRepositoryImpl implements MeasurementRepository {
  MeasurementRepositoryImpl(this._firestore, this._paths);

  final FirebaseFirestore _firestore;
  final FirestorePaths _paths;

  @override
  Stream<List<WeightEntry>> watchWeights() {
    return _firestore
        .collection(_paths.weightEntries)
        .orderBy('dateTime')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => WeightEntryMapper.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  @override
  Future<void> saveWeight(WeightEntry entry) {
    return _firestore
        .collection(_paths.weightEntries)
        .doc(entry.id)
        .set(WeightEntryMapper.toMap(entry));
  }

  @override
  Future<void> deleteWeight(String id) {
    return _firestore.collection(_paths.weightEntries).doc(id).delete();
  }

  @override
  Stream<List<BodyMeasureEntry>> watchBodyMeasures() {
    return _firestore
        .collection(_paths.bodyMeasureEntries)
        .orderBy('date')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => BodyMeasureEntryMapper.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  @override
  Future<void> saveBodyMeasure(BodyMeasureEntry entry) {
    return _firestore
        .collection(_paths.bodyMeasureEntries)
        .doc(entry.id)
        .set(BodyMeasureEntryMapper.toMap(entry));
  }

  @override
  Future<void> deleteBodyMeasure(String id) {
    return _firestore.collection(_paths.bodyMeasureEntries).doc(id).delete();
  }
}
