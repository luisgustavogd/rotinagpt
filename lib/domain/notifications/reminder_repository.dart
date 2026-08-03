import 'reminder.dart';

abstract class ReminderRepository {
  Stream<List<Reminder>> watchAll();

  Future<void> save(Reminder reminder);

  Future<void> delete(String reminderId);
}
