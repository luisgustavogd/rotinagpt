/// Cálculo de IMC — puramente informativo, nunca usado para diagnosticar ou
/// prescrever (este app não é um dispositivo médico).
class BmiCalculator {
  const BmiCalculator._();

  /// Ponto central da faixa de peso normal (IMC 18,5–25,0) usada como
  /// sugestão inicial de meta de peso.
  static const centralBmi = 21.75;

  static double? bmi(double weightKg, double? heightCm) {
    if (heightCm == null || heightCm <= 0) return null;
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  /// Peso (kg) correspondente ao IMC central para a altura informada.
  static double? suggestedTargetWeightKg(double? heightCm) {
    if (heightCm == null || heightCm <= 0) return null;
    final heightM = heightCm / 100;
    return centralBmi * heightM * heightM;
  }
}
