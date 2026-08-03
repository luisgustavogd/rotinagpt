/// RF-070/RF-071 — cadastro manual de exame. RF-073 — nunca interpretado
/// como diagnóstico; a UI só descreve a evolução ("aumentou"/"diminuiu").
class LabResult {
  const LabResult({
    required this.id,
    required this.date,
    required this.markerName,
    required this.result,
    required this.unit,
    this.reference,
    this.origin,
  });

  final String id;
  final DateTime date;

  /// Ex.: "Colesterol total", "LDL", "HDL", "Triglicerídeos", "Glicemia",
  /// "Hemoglobina glicada" (RF-071 traz esses como modelos prontos na UI).
  final String markerName;
  final double result;
  final String unit;
  final String? reference;
  final String? origin;
}
