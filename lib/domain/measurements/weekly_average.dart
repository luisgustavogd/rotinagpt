import 'weight_entry.dart';

class WeightTrendPoint {
  const WeightTrendPoint({required this.date, required this.movingAverageKg});

  final DateTime date;
  final double movingAverageKg;
}

/// RF-032/RN-004 — média móvel semanal de peso, para reduzir a interpretação
/// excessiva de oscilações diárias. Usa apenas registros válidos e nunca
/// exclui outliers automaticamente (a decisão de descartar um registro é
/// sempre do usuário, editando/apagando o lançamento).
class WeeklyAverageCalculator {
  const WeeklyAverageCalculator();

  /// Um ponto de média móvel por dia que tem ao menos um registro dentro da
  /// janela de [windowDays] dias terminando naquele dia.
  List<WeightTrendPoint> movingAverage(
    List<WeightEntry> entries, {
    int windowDays = 7,
  }) {
    if (entries.isEmpty) return [];
    final sorted = [...entries]
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final days = <DateTime>{};
    for (final e in sorted) {
      days.add(DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day));
    }
    final orderedDays = days.toList()..sort();

    final points = <WeightTrendPoint>[];
    for (final day in orderedDays) {
      final windowStart = day.subtract(Duration(days: windowDays - 1));
      final windowEntries = sorted.where((e) {
        final d = DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day);
        return !d.isBefore(windowStart) && !d.isAfter(day);
      }).toList();
      if (windowEntries.isEmpty) continue;
      final avg =
          windowEntries.fold(0.0, (sum, e) => sum + e.weightKg) /
          windowEntries.length;
      points.add(WeightTrendPoint(date: day, movingAverageKg: avg));
    }
    return points;
  }
}
