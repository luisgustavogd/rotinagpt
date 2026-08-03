import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/profile/goal_history_entry.dart';
import '../../../domain/profile/user_profile.dart';

class ProfileMapper {
  const ProfileMapper._();

  static Map<String, dynamic> toMap(UserProfile profile) => {
    'name': profile.name,
    'initialWeightKg': profile.initialWeightKg,
    'heightCm': profile.heightCm,
    'targetWeightKg': profile.targetWeightKg,
    'targetProteinG': profile.targetProteinG,
    'wakeTime': profile.wakeTime,
    'sleepTime': profile.sleepTime,
    'restrictions': profile.restrictions,
    'avoidedFoods': profile.avoidedFoods,
    'noEatAfter': profile.noEatAfter,
  };

  static UserProfile fromMap(Map<String, dynamic> map) => UserProfile(
    name: map['name'] as String?,
    initialWeightKg: (map['initialWeightKg'] as num).toDouble(),
    heightCm: (map['heightCm'] as num?)?.toDouble(),
    targetWeightKg: (map['targetWeightKg'] as num).toDouble(),
    targetProteinG: (map['targetProteinG'] as num).toDouble(),
    wakeTime: map['wakeTime'] as String,
    sleepTime: map['sleepTime'] as String,
    restrictions: List<String>.from(map['restrictions'] as List? ?? []),
    avoidedFoods: List<String>.from(map['avoidedFoods'] as List? ?? []),
    noEatAfter: map['noEatAfter'] as String?,
  );
}

class GoalHistoryMapper {
  const GoalHistoryMapper._();

  static Map<String, dynamic> toMap(GoalHistoryEntry entry) => {
    'kind': entry.kind.name,
    'value': entry.value,
    'effectiveDate': Timestamp.fromDate(entry.effectiveDate),
  };

  static GoalHistoryEntry fromMap(String id, Map<String, dynamic> map) {
    return GoalHistoryEntry(
      id: id,
      kind: GoalKind.values.byName(map['kind'] as String),
      value: (map['value'] as num).toDouble(),
      effectiveDate: (map['effectiveDate'] as Timestamp).toDate(),
    );
  }
}
