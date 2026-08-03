/// RF-081 — resumo semanal: adesão, proteína média, variação de peso e
/// minutos de atividade.
class WeeklySummary {
  const WeeklySummary({
    required this.weekStart,
    required this.averageProteinG,
    required this.weightVariationKg,
    required this.activityMinutes,
    required this.completedActivities,
    required this.partialActivities,
    required this.daysWithMealsConfirmed,
  });

  final DateTime weekStart;
  final double averageProteinG;

  /// Peso no fim da semana menos peso no início (negativo = perdeu peso).
  final double? weightVariationKg;
  final int activityMinutes;
  final int completedActivities;
  final int partialActivities;
  final int daysWithMealsConfirmed;
}
