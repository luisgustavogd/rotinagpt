import 'activity_entry.dart';
import 'activity_plan.dart';

abstract class ActivityRepository {
  Stream<List<ActivityPlan>> watchPlans();

  Future<void> savePlan(ActivityPlan plan);

  Future<void> deletePlan(String planId);

  Stream<List<ActivityEntry>> watchEntries();

  Future<void> saveEntry(ActivityEntry entry);

  Future<void> deleteEntry(String entryId);
}
