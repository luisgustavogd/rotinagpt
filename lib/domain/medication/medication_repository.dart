import 'medication_entry.dart';
import 'medication_plan.dart';

abstract class MedicationRepository {
  Stream<List<MedicationPlan>> watchPlans();

  Future<void> savePlan(MedicationPlan plan);

  Future<void> deletePlan(String planId);

  Stream<List<MedicationEntry>> watchEntries();

  Future<void> saveEntry(MedicationEntry entry);

  Future<void> deleteEntry(String entryId);
}
