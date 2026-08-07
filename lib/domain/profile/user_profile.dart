import 'protein_target_calculator.dart';

/// RF-001/RF-002/RF-003 — perfil pessoal. Somente o essencial: nada aqui é
/// coletado por obrigatório além do que o app precisa para montar o painel do
/// dia e as metas.
class UserProfile {
  const UserProfile({
    this.name,
    required this.initialWeightKg,
    this.heightCm,
    required this.targetWeightKg,
    required this.targetProteinG,
    this.proteinActivityLevel,
    required this.wakeTime,
    required this.sleepTime,
    this.restrictions = const [],
    this.avoidedFoods = const [],
    this.noEatAfter,
  });

  /// Nome opcional (RF-001).
  final String? name;
  final double initialWeightKg;
  final double? heightCm;
  final double targetWeightKg;

  /// Meta diária de proteína em gramas (RF-002). Pode ser sugerida a partir
  /// de [proteinActivityLevel] e do peso, ou digitada manualmente — o app
  /// sempre deve exibir o aviso de que o valor precisa ser validado por
  /// profissional (ver copy em features/onboarding).
  final double targetProteinG;

  /// Base usada para a última sugestão de [targetProteinG] (ver
  /// ProteinTargetCalculator e docs/NUTRICAO.md). Null quando o valor foi só
  /// digitado manualmente, sem usar a calculadora.
  final ProteinActivityLevel? proteinActivityLevel;

  /// Horário habitual, formato "HH:mm".
  final String wakeTime;
  final String sleepTime;

  /// RF-003 — restrições e preferências (ex.: "refluxo").
  final List<String> restrictions;
  final List<String> avoidedFoods;

  /// Horário a partir do qual o usuário prefere não comer (RF-029), "HH:mm".
  final String? noEatAfter;

  UserProfile copyWith({
    String? name,
    double? initialWeightKg,
    double? heightCm,
    double? targetWeightKg,
    double? targetProteinG,
    ProteinActivityLevel? proteinActivityLevel,
    String? wakeTime,
    String? sleepTime,
    List<String>? restrictions,
    List<String>? avoidedFoods,
    String? noEatAfter,
  }) {
    return UserProfile(
      name: name ?? this.name,
      initialWeightKg: initialWeightKg ?? this.initialWeightKg,
      heightCm: heightCm ?? this.heightCm,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      targetProteinG: targetProteinG ?? this.targetProteinG,
      proteinActivityLevel: proteinActivityLevel ?? this.proteinActivityLevel,
      wakeTime: wakeTime ?? this.wakeTime,
      sleepTime: sleepTime ?? this.sleepTime,
      restrictions: restrictions ?? this.restrictions,
      avoidedFoods: avoidedFoods ?? this.avoidedFoods,
      noEatAfter: noEatAfter ?? this.noEatAfter,
    );
  }
}
