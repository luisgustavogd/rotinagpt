import 'meal_unit.dart';

/// RF-022/RF-023 — alimento pessoal cadastrado pelo usuário (sem base pública
/// externa no MVP).
class Food {
  const Food({
    required this.id,
    required this.name,
    required this.defaultPortion,
    required this.unit,
    required this.proteinG,
    this.caloriesKcal,
    this.favorite = false,
  });

  final String id;
  final String name;

  /// Quantidade de referência (na unidade [unit]) para a qual [proteinG] e
  /// [caloriesKcal] são válidos.
  final double defaultPortion;
  final MealUnit unit;
  final double proteinG;

  /// RF-027 — calorias são sempre opcionais.
  final double? caloriesKcal;

  /// RF-023 — refeições/alimentos favoritos, para lançamento em 1 toque.
  final bool favorite;

  Food copyWith({
    String? name,
    double? defaultPortion,
    MealUnit? unit,
    double? proteinG,
    double? caloriesKcal,
    bool? favorite,
  }) {
    return Food(
      id: id,
      name: name ?? this.name,
      defaultPortion: defaultPortion ?? this.defaultPortion,
      unit: unit ?? this.unit,
      proteinG: proteinG ?? this.proteinG,
      caloriesKcal: caloriesKcal ?? this.caloriesKcal,
      favorite: favorite ?? this.favorite,
    );
  }

  /// Proteína (g) para uma dada [quantity] na mesma unidade de [unit].
  double proteinFor(double quantity) {
    if (defaultPortion <= 0) return 0;
    return proteinG * (quantity / defaultPortion);
  }

  /// Calorias (kcal) para uma dada [quantity], ou null se calorias não
  /// informadas para este alimento (RF-027).
  double? caloriesFor(double quantity) {
    final cal = caloriesKcal;
    if (cal == null || defaultPortion <= 0) return null;
    return cal * (quantity / defaultPortion);
  }
}
