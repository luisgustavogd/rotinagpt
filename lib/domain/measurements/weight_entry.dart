class WeightEntry {
  const WeightEntry({
    required this.id,
    required this.dateTime,
    required this.weightKg,
    this.observation,
  });

  final String id;
  final DateTime dateTime;
  final double weightKg;
  final String? observation;
}
