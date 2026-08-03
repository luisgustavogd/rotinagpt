import 'activity_type.dart';

/// RF-050 — plano semanal de atividades. RF-053 — a progressão (duração e
/// intensidade) é sempre alterada manualmente pelo usuário; o app nunca
/// aumenta o treino sozinho.
class ActivityPlan {
  const ActivityPlan({
    required this.id,
    required this.weekday,
    required this.type,
    required this.durationMin,
    required this.perceivedIntensity,
    this.observation,
    this.active = true,
  });

  final String id;

  /// 1 (segunda) a 7 (domingo), ISO-8601.
  final int weekday;
  final ActivityType type;
  final int durationMin;

  /// 0 a 10 (RF-052 — esforço percebido / teste da fala como referência).
  final int perceivedIntensity;
  final String? observation;
  final bool active;

  ActivityPlan copyWith({
    int? weekday,
    ActivityType? type,
    int? durationMin,
    int? perceivedIntensity,
    String? observation,
    bool? active,
  }) {
    return ActivityPlan(
      id: id,
      weekday: weekday ?? this.weekday,
      type: type ?? this.type,
      durationMin: durationMin ?? this.durationMin,
      perceivedIntensity: perceivedIntensity ?? this.perceivedIntensity,
      observation: observation ?? this.observation,
      active: active ?? this.active,
    );
  }
}
