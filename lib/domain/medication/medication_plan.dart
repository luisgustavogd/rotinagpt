/// RF-040 — cadastro informativo, nunca prescritivo: o app registra o que o
/// profissional prescreveu, mas nunca sugere alterá-lo (RF-044).
class MedicationPlan {
  const MedicationPlan({
    required this.id,
    required this.name,
    required this.prescribedDose,
    required this.frequency,
    required this.weekdays,
    required this.time,
  });

  final String id;
  final String name;

  /// Texto livre (ex.: "5mg") — evita impor uma unidade específica.
  final String prescribedDose;

  /// Texto livre (ex.: "semanal").
  final String frequency;

  /// 1 (segunda) a 7 (domingo), ISO-8601.
  final List<int> weekdays;

  /// "HH:mm".
  final String time;
}
