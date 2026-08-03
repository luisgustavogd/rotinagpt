import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/medication/medication_entry.dart';
import '../../../domain/medication/medication_plan.dart';
import '../../../domain/medication/medication_repository.dart';
import '../firestore_paths.dart';
import '../mappers/medication_mapper.dart';

class MedicationRepositoryImpl implements MedicationRepository {
  MedicationRepositoryImpl(this._firestore, this._paths);

  final FirebaseFirestore _firestore;
  final FirestorePaths _paths;

  @override
  Stream<List<MedicationPlan>> watchPlans() {
    return _firestore
        .collection(_paths.medicationPlans)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => MedicationPlanMapper.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  @override
  Future<void> savePlan(MedicationPlan plan) {
    return _firestore
        .collection(_paths.medicationPlans)
        .doc(plan.id)
        .set(MedicationPlanMapper.toMap(plan));
  }

  @override
  Future<void> deletePlan(String planId) {
    return _firestore.collection(_paths.medicationPlans).doc(planId).delete();
  }

  @override
  Stream<List<MedicationEntry>> watchEntries() {
    return _firestore
        .collection(_paths.medicationEntries)
        .orderBy('dateTime')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => MedicationEntryMapper.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  @override
  Future<void> saveEntry(MedicationEntry entry) {
    return _firestore
        .collection(_paths.medicationEntries)
        .doc(entry.id)
        .set(MedicationEntryMapper.toMap(entry));
  }

  @override
  Future<void> deleteEntry(String entryId) {
    return _firestore
        .collection(_paths.medicationEntries)
        .doc(entryId)
        .delete();
  }
}
