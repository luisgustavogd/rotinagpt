import 'dart:typed_data';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rotinagpt/data/backup/backup_reader.dart';
import 'package:rotinagpt/data/backup/backup_service.dart';
import 'package:rotinagpt/data/remote/firestore_paths.dart';
import 'package:rotinagpt/data/remote/repositories/activity_repository_impl.dart';
import 'package:rotinagpt/data/remote/repositories/food_repository_impl.dart';
import 'package:rotinagpt/data/remote/repositories/lab_repository_impl.dart';
import 'package:rotinagpt/data/remote/repositories/meal_repository_impl.dart';
import 'package:rotinagpt/data/remote/repositories/measurement_repository_impl.dart';
import 'package:rotinagpt/data/remote/repositories/medication_repository_impl.dart';
import 'package:rotinagpt/data/remote/repositories/profile_repository_impl.dart';
import 'package:rotinagpt/data/remote/repositories/reminder_repository_impl.dart';
import 'package:rotinagpt/domain/measurements/weight_entry.dart';
import 'package:rotinagpt/domain/nutrition/food.dart';
import 'package:rotinagpt/domain/nutrition/meal_unit.dart';
import 'package:rotinagpt/domain/profile/user_profile.dart';

BackupService _serviceFor(
  FakeFirebaseFirestore firestore,
  FirestorePaths paths,
) {
  return BackupService(
    profileRepository: ProfileRepositoryImpl(firestore, paths),
    foodRepository: FoodRepositoryImpl(firestore, paths),
    mealRepository: MealRepositoryImpl(firestore, paths),
    measurementRepository: MeasurementRepositoryImpl(firestore, paths),
    medicationRepository: MedicationRepositoryImpl(firestore, paths),
    activityRepository: ActivityRepositoryImpl(firestore, paths),
    labRepository: LabRepositoryImpl(firestore, paths),
    reminderRepository: ReminderRepositoryImpl(firestore, paths),
  );
}

void main() {
  test(
    'RF-083/RNF-008: backup gerado é válido e passa na checagem de checksum/versão',
    () async {
      final firestore = FakeFirebaseFirestore();
      const paths = FirestorePaths('user-1');

      await ProfileRepositoryImpl(firestore, paths).saveProfile(
        const UserProfile(
          initialWeightKg: 90,
          targetWeightKg: 80,
          targetProteinG: 130,
          wakeTime: '05:00',
          sleepTime: '22:00',
        ),
      );
      await FoodRepositoryImpl(firestore, paths).save(
        const Food(
          id: 'f1',
          name: 'Ovo',
          defaultPortion: 100,
          unit: MealUnit.grams,
          proteinG: 13,
        ),
      );
      await MeasurementRepositoryImpl(firestore, paths).saveWeight(
        WeightEntry(id: 'w1', dateTime: DateTime(2026, 8, 3), weightKg: 90),
      );

      final Uint8List archive = await _serviceFor(
        firestore,
        paths,
      ).buildBackupArchive();

      final reader = BackupReader(firestore: firestore, paths: paths);
      final parsed = reader.parseAndValidate(archive);

      expect(parsed.manifest.version, kBackupFormatVersion);
      expect(parsed.data['foods'], hasLength(1));
      expect(parsed.data['weightEntries'], hasLength(1));

      // RN-010: como os dados no Firestore não mudaram desde o backup, o
      // preview não deve indicar nenhuma criação/atualização pendente.
      final preview = await reader.computePreview(parsed);
      expect(preview.hasChanges, isFalse);
    },
  );

  test(
    'RF-084/RN-010: restaurar em uma base vazia recria os dados e é idempotente',
    () async {
      final sourceFirestore = FakeFirebaseFirestore();
      const paths = FirestorePaths('user-1');
      await FoodRepositoryImpl(sourceFirestore, paths).save(
        const Food(
          id: 'f1',
          name: 'Ovo',
          defaultPortion: 100,
          unit: MealUnit.grams,
          proteinG: 13,
        ),
      );
      final archive = await _serviceFor(
        sourceFirestore,
        paths,
      ).buildBackupArchive();

      final targetFirestore = FakeFirebaseFirestore();
      final reader = BackupReader(firestore: targetFirestore, paths: paths);
      final parsed = reader.parseAndValidate(archive);

      final firstPreview = await reader.computePreview(parsed);
      expect(
        firstPreview.diffs.firstWhere((d) => d.collection == 'foods').toCreate,
        1,
      );

      await reader.applyRestore(parsed);
      final foods = await FoodRepositoryImpl(
        targetFirestore,
        paths,
      ).watchAll().first;
      expect(foods, hasLength(1));
      expect(foods.single.name, 'Ovo');

      // Reaplicar o mesmo backup não duplica (idempotente pelo id original).
      await reader.applyRestore(parsed);
      final foodsAfterSecondApply = await FoodRepositoryImpl(
        targetFirestore,
        paths,
      ).watchAll().first;
      expect(foodsAfterSecondApply, hasLength(1));
    },
  );
}
