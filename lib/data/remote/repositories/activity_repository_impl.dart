import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/activity/activity_entry.dart';
import '../../../domain/activity/activity_plan.dart';
import '../../../domain/activity/activity_repository.dart';
import '../firestore_paths.dart';
import '../mappers/activity_mapper.dart';

class ActivityRepositoryImpl implements ActivityRepository {
  ActivityRepositoryImpl(this._firestore, this._paths);

  final FirebaseFirestore _firestore;
  final FirestorePaths _paths;

  @override
  Stream<List<ActivityPlan>> watchPlans() {
    return _firestore
        .collection(_paths.activityPlans)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ActivityPlanMapper.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  @override
  Future<void> savePlan(ActivityPlan plan) {
    return _firestore
        .collection(_paths.activityPlans)
        .doc(plan.id)
        .set(ActivityPlanMapper.toMap(plan));
  }

  @override
  Future<void> deletePlan(String planId) {
    return _firestore.collection(_paths.activityPlans).doc(planId).delete();
  }

  @override
  Stream<List<ActivityEntry>> watchEntries() {
    return _firestore
        .collection(_paths.activityEntries)
        .orderBy('dateTime')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ActivityEntryMapper.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  @override
  Future<void> saveEntry(ActivityEntry entry) {
    return _firestore
        .collection(_paths.activityEntries)
        .doc(entry.id)
        .set(ActivityEntryMapper.toMap(entry));
  }

  @override
  Future<void> deleteEntry(String entryId) {
    return _firestore.collection(_paths.activityEntries).doc(entryId).delete();
  }
}
