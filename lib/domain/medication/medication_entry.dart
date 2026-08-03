/// RF-043 — sintoma autorrelatado após a aplicação, com intensidade 0-10.
/// Nunca gera diagnóstico automático (RN-006).
class SymptomRecord {
  const SymptomRecord({required this.name, required this.intensity});

  final String name;

  /// 0 a 10.
  final int intensity;
}

/// RF-041 — aplicação de medicação.
class MedicationEntry {
  const MedicationEntry({
    required this.id,
    required this.planId,
    required this.dateTime,
    required this.dose,
    required this.applicationSite,
    this.symptoms = const [],
    this.observation,
  });

  final String id;
  final String planId;
  final DateTime dateTime;
  final String dose;
  final String applicationSite;
  final List<SymptomRecord> symptoms;
  final String? observation;
}
