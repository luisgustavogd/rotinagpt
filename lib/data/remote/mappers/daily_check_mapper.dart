import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/notifications/daily_check.dart';

class DailyCheckMapper {
  const DailyCheckMapper._();

  static Map<String, dynamic> toMap(DailyCheck check) => {
    'date': Timestamp.fromDate(check.date),
    'habitLabel': check.habitLabel,
    'status': check.status.name,
    'completedAt': check.completedAt == null
        ? null
        : Timestamp.fromDate(check.completedAt!),
  };

  static DailyCheck fromMap(String id, Map<String, dynamic> map) => DailyCheck(
    id: id,
    date: (map['date'] as Timestamp).toDate(),
    habitLabel: map['habitLabel'] as String,
    status: DailyCheckStatus.values.byName(map['status'] as String),
    completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
  );
}
