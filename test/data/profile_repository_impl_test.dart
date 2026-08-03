import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rotinagpt/data/remote/firestore_paths.dart';
import 'package:rotinagpt/data/remote/repositories/profile_repository_impl.dart';
import 'package:rotinagpt/domain/profile/goal_history_entry.dart';
import 'package:rotinagpt/domain/profile/user_profile.dart';

void main() {
  test(
    'salva e observa o perfil restrito a /users/{uid}/profile/main',
    () async {
      final firestore = FakeFirebaseFirestore();
      final repo = ProfileRepositoryImpl(
        firestore,
        const FirestorePaths('user-1'),
      );

      expect(await repo.watchProfile().first, isNull);

      const profile = UserProfile(
        name: 'Luis',
        initialWeightKg: 90,
        targetWeightKg: 80,
        targetProteinG: 130,
        wakeTime: '05:00',
        sleepTime: '22:00',
      );
      await repo.saveProfile(profile);

      final loaded = await repo.watchProfile().first;
      expect(loaded?.name, 'Luis');
      expect(loaded?.targetProteinG, 130);
    },
  );

  test(
    'RN-008: histórico de metas é append-only e ordenado por data',
    () async {
      final firestore = FakeFirebaseFirestore();
      final repo = ProfileRepositoryImpl(
        firestore,
        const FirestorePaths('user-1'),
      );

      await repo.addGoalHistoryEntry(
        GoalHistoryEntry(
          id: '2',
          kind: GoalKind.protein,
          value: 130,
          effectiveDate: DateTime(2026, 6, 1),
        ),
      );
      await repo.addGoalHistoryEntry(
        GoalHistoryEntry(
          id: '1',
          kind: GoalKind.protein,
          value: 100,
          effectiveDate: DateTime(2026, 1, 1),
        ),
      );

      final history = await repo.watchGoalHistory().first;
      expect(history.map((e) => e.value), [100, 130]);
    },
  );
}
