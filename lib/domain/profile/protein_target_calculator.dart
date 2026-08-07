/// Sugestão de meta diária de proteína — ver docs/NUTRICAO.md para a
/// metodologia completa e a referência ao estudo usado (ISSN Position
/// Stand: Protein and Exercise, Jäger et al., 2017).
enum ProteinActivityLevel {
  sedentary,
  active,
  caloricDeficitTraining;

  String get label => switch (this) {
    ProteinActivityLevel.sedentary => 'Sedentário(a)',
    ProteinActivityLevel.active => 'Fisicamente ativo(a), sem déficit calórico',
    ProteinActivityLevel.caloricDeficitTraining =>
      'Em déficit calórico, com treino de força',
  };
}

class ProteinTargetCalculator {
  const ProteinTargetCalculator._();

  /// Ponto central da faixa de g de proteína por kg de peso corporal
  /// recomendada pelo estudo para cada nível de atividade.
  static const Map<ProteinActivityLevel, double> centralGPerKg = {
    ProteinActivityLevel.sedentary: 0.8,
    ProteinActivityLevel.active: 1.7,
    ProteinActivityLevel.caloricDeficitTraining: 2.7,
  };

  static double suggestedTargetProteinG(
    double weightKg,
    ProteinActivityLevel level,
  ) => weightKg * centralGPerKg[level]!;
}
