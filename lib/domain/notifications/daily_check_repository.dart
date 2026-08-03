import 'daily_check.dart';

abstract class DailyCheckRepository {
  Stream<List<DailyCheck>> watchForDate(DateTime date);

  Future<void> save(DailyCheck check);
}
