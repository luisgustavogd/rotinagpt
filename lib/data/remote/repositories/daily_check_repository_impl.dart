import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/notifications/daily_check.dart';
import '../../../domain/notifications/daily_check_repository.dart';
import '../firestore_paths.dart';
import '../mappers/daily_check_mapper.dart';

class DailyCheckRepositoryImpl implements DailyCheckRepository {
  DailyCheckRepositoryImpl(this._firestore, this._paths);

  final FirebaseFirestore _firestore;
  final FirestorePaths _paths;

  @override
  Stream<List<DailyCheck>> watchForDate(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return _firestore
        .collection(_paths.dailyChecks)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
        .where('date', isLessThan: Timestamp.fromDate(dayEnd))
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => DailyCheckMapper.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  @override
  Future<void> save(DailyCheck check) {
    return _firestore
        .collection(_paths.dailyChecks)
        .doc(check.id)
        .set(DailyCheckMapper.toMap(check));
  }
}
