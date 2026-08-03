import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/activity/activity_entry.dart';
import '../../../domain/activity/activity_plan.dart';
import '../../../domain/activity/activity_type.dart';

class ActivityPlanMapper {
  const ActivityPlanMapper._();

  static Map<String, dynamic> toMap(ActivityPlan plan) => {
    'weekday': plan.weekday,
    'type': plan.type.name,
    'durationMin': plan.durationMin,
    'perceivedIntensity': plan.perceivedIntensity,
    'observation': plan.observation,
    'active': plan.active,
  };

  static ActivityPlan fromMap(String id, Map<String, dynamic> map) =>
      ActivityPlan(
        id: id,
        weekday: map['weekday'] as int,
        type: ActivityType.values.byName(map['type'] as String),
        durationMin: map['durationMin'] as int,
        perceivedIntensity: map['perceivedIntensity'] as int,
        observation: map['observation'] as String?,
        active: map['active'] as bool? ?? true,
      );
}

class ActivityEntryMapper {
  const ActivityEntryMapper._();

  static Map<String, dynamic> toMap(ActivityEntry entry) => {
    'planId': entry.planId,
    'dateTime': Timestamp.fromDate(entry.dateTime),
    'type': entry.type.name,
    'durationMin': entry.durationMin,
    'perceivedEffort': entry.perceivedEffort,
    'status': entry.status.name,
    'observation': entry.observation,
  };

  static ActivityEntry fromMap(String id, Map<String, dynamic> map) =>
      ActivityEntry(
        id: id,
        planId: map['planId'] as String?,
        dateTime: (map['dateTime'] as Timestamp).toDate(),
        type: ActivityType.values.byName(map['type'] as String),
        durationMin: map['durationMin'] as int,
        perceivedEffort: map['perceivedEffort'] as int,
        status: ActivityStatus.values.byName(map['status'] as String),
        observation: map['observation'] as String?,
      );
}
