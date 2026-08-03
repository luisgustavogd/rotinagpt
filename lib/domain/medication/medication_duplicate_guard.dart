import 'medication_entry.dart';

/// RN-005 — uma aplicação de medicação não pode ser duplicada acidentalmente
/// sem confirmação: se já existe um registro muito próximo no tempo para o
/// mesmo plano, a UI deve pedir confirmação antes de salvar um novo.
class MedicationDuplicateGuard {
  const MedicationDuplicateGuard();

  bool isLikelyDuplicate({
    required List<MedicationEntry> existingEntries,
    required String planId,
    required DateTime candidateDateTime,
    Duration within = const Duration(hours: 2),
  }) {
    return existingEntries.any((e) {
      if (e.planId != planId) return false;
      final diff = candidateDateTime.difference(e.dateTime).abs();
      return diff <= within;
    });
  }
}
