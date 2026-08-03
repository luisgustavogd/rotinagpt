import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/profile/goal_history_entry.dart';
import '../../../domain/profile/profile_repository.dart';
import '../../../domain/profile/user_profile.dart';
import '../firestore_paths.dart';
import '../mappers/profile_mapper.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._firestore, this._paths);

  final FirebaseFirestore _firestore;
  final FirestorePaths _paths;

  @override
  Stream<UserProfile?> watchProfile() {
    return _firestore.doc(_paths.profileDoc).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return null;
      return ProfileMapper.fromMap(data);
    });
  }

  @override
  Future<void> saveProfile(UserProfile profile) {
    return _firestore.doc(_paths.profileDoc).set(ProfileMapper.toMap(profile));
  }

  @override
  Stream<List<GoalHistoryEntry>> watchGoalHistory() {
    return _firestore
        .collection(_paths.goalHistory)
        .orderBy('effectiveDate')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => GoalHistoryMapper.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  @override
  Future<void> addGoalHistoryEntry(GoalHistoryEntry entry) {
    return _firestore
        .collection(_paths.goalHistory)
        .doc(entry.id)
        .set(GoalHistoryMapper.toMap(entry));
  }
}
