import 'meal_item.dart';

enum MealType { breakfast, lunch, snack, dinner, other }

/// RN-003 — refeições planejadas não entram no "consumido" até confirmadas.
enum MealStatus { planned, confirmed, skipped }

/// RF-028 — sintomas de tolerância autorrelatados após a refeição. Nunca
/// interpretados automaticamente como diagnóstico (RN-006).
enum ToleranceSymptom {
  satiety,
  nausea,
  reflux,
  constipation,
  diarrhea,
  discomfort,
}

class MealEntry {
  const MealEntry({
    required this.id,
    required this.dateTime,
    required this.mealType,
    required this.items,
    this.status = MealStatus.planned,
    this.toleranceSymptoms = const [],
    this.observation,
  });

  final String id;
  final DateTime dateTime;
  final MealType mealType;
  final List<MealItem> items;
  final MealStatus status;
  final List<ToleranceSymptom> toleranceSymptoms;
  final String? observation;

  /// RF-026 — soma automática da proteína dos itens da refeição.
  double get totalProteinG => items.fold(0, (sum, i) => sum + i.proteinG);

  /// RF-027 — soma de calorias só se todos os itens tiverem calorias
  /// informadas; caso contrário, o total é indefinido (não estimamos).
  double? get totalCaloriesKcal {
    if (items.isEmpty) return null;
    var total = 0.0;
    for (final item in items) {
      final cal = item.caloriesKcal;
      if (cal == null) return null;
      total += cal;
    }
    return total;
  }

  MealEntry copyWith({
    DateTime? dateTime,
    MealType? mealType,
    List<MealItem>? items,
    MealStatus? status,
    List<ToleranceSymptom>? toleranceSymptoms,
    String? observation,
  }) {
    return MealEntry(
      id: id,
      dateTime: dateTime ?? this.dateTime,
      mealType: mealType ?? this.mealType,
      items: items ?? this.items,
      status: status ?? this.status,
      toleranceSymptoms: toleranceSymptoms ?? this.toleranceSymptoms,
      observation: observation ?? this.observation,
    );
  }
}
