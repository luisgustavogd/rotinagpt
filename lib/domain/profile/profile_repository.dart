import 'goal_history_entry.dart';
import 'user_profile.dart';

abstract class ProfileRepository {
  Stream<UserProfile?> watchProfile();

  Future<void> saveProfile(UserProfile profile);

  Stream<List<GoalHistoryEntry>> watchGoalHistory();

  Future<void> addGoalHistoryEntry(GoalHistoryEntry entry);
}
