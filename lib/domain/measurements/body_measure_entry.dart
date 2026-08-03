/// RF-031 — circunferência abdominal.
class BodyMeasureEntry {
  const BodyMeasureEntry({
    required this.id,
    required this.date,
    required this.waistCm,
    this.observation,
  });

  final String id;
  final DateTime date;
  final double waistCm;
  final String? observation;
}
