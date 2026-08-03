import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/notifications/reminder.dart';
import '../../../domain/notifications/reminder_repository.dart';
import '../firestore_paths.dart';
import '../mappers/reminder_mapper.dart';

class ReminderRepositoryImpl implements ReminderRepository {
  ReminderRepositoryImpl(this._firestore, this._paths);

  final FirebaseFirestore _firestore;
  final FirestorePaths _paths;

  @override
  Stream<List<Reminder>> watchAll() {
    return _firestore
        .collection(_paths.reminders)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ReminderMapper.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  @override
  Future<void> save(Reminder reminder) {
    return _firestore
        .collection(_paths.reminders)
        .doc(reminder.id)
        .set(ReminderMapper.toMap(reminder));
  }

  @override
  Future<void> delete(String reminderId) {
    return _firestore.collection(_paths.reminders).doc(reminderId).delete();
  }
}
