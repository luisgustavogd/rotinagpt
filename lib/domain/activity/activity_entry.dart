import 'activity_type.dart';

/// RF-051/RN-007 — execução total, parcial ou não realizada; "parcial" é um
/// status distinto de "completa" nos relatórios de adesão.
enum ActivityStatus { completed, partial, notDone }

class ActivityEntry {
  const ActivityEntry({
    required this.id,
    this.planId,
    required this.dateTime,
    required this.type,
    required this.durationMin,
    required this.perceivedEffort,
    required this.status,
    this.observation,
  });

  final String id;
  final String? planId;
  final DateTime dateTime;
  final ActivityType type;
  final int durationMin;

  /// 0 a 10.
  final int perceivedEffort;
  final ActivityStatus status;
  final String? observation;
}
