import 'package:flutter_test/flutter_test.dart';
import 'package:rotinagpt/domain/measurements/weekly_average.dart';
import 'package:rotinagpt/domain/measurements/weight_entry.dart';

void main() {
  test('RF-032/RN-004: média móvel semanal usa só registros válidos', () {
    final entries = [
      WeightEntry(id: '1', dateTime: DateTime(2026, 8, 1), weightKg: 90),
      WeightEntry(id: '2', dateTime: DateTime(2026, 8, 2), weightKg: 89),
      WeightEntry(
        id: '3',
        dateTime: DateTime(2026, 8, 3),
        weightKg: 200,
      ), // outlier: não é excluído automaticamente
    ];

    final points = const WeeklyAverageCalculator().movingAverage(
      entries,
      windowDays: 7,
    );

    expect(points.length, 3);
    // No terceiro dia, a média da janela inclui o outlier (não descartado).
    expect(points.last.movingAverageKg, closeTo((90 + 89 + 200) / 3, 0.001));
  });

  test('lista vazia retorna nenhum ponto', () {
    expect(const WeeklyAverageCalculator().movingAverage([]), isEmpty);
  });
}
