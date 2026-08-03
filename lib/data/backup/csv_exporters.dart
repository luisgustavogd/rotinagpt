import '../../domain/activity/activity_entry.dart';
import '../../domain/measurements/weight_entry.dart';
import '../../domain/nutrition/meal_entry.dart';

/// RF-082 — exportação de dados em CSV.
class CsvExporters {
  const CsvExporters._();

  static String meals(List<MealEntry> meals) {
    final rows = <List<String>>[
      [
        'Data/Hora',
        'Tipo',
        'Status',
        'Alimentos',
        'Proteina(g)',
        'Calorias(kcal)',
        'Observacao',
      ],
      for (final m in meals)
        [
          m.dateTime.toIso8601String(),
          m.mealType.name,
          m.status.name,
          m.items
              .map((i) => '${i.foodNameSnapshot} (${i.quantity})')
              .join('; '),
          m.totalProteinG.toStringAsFixed(1),
          m.totalCaloriesKcal?.toStringAsFixed(0) ?? '',
          m.observation ?? '',
        ],
    ];
    return _toCsv(rows);
  }

  static String weights(List<WeightEntry> entries) {
    final rows = <List<String>>[
      ['Data/Hora', 'Peso(kg)', 'Observacao'],
      for (final w in entries)
        [
          w.dateTime.toIso8601String(),
          w.weightKg.toString(),
          w.observation ?? '',
        ],
    ];
    return _toCsv(rows);
  }

  static String activities(List<ActivityEntry> entries) {
    final rows = <List<String>>[
      [
        'Data/Hora',
        'Tipo',
        'Duracao(min)',
        'Esforco(0-10)',
        'Status',
        'Observacao',
      ],
      for (final a in entries)
        [
          a.dateTime.toIso8601String(),
          a.type.name,
          a.durationMin.toString(),
          a.perceivedEffort.toString(),
          a.status.name,
          a.observation ?? '',
        ],
    ];
    return _toCsv(rows);
  }

  static String _toCsv(List<List<String>> rows) {
    return rows.map((row) => row.map(_escape).join(',')).join('\n');
  }

  static String _escape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
