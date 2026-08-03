import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';

import '../../domain/activity/activity_repository.dart';
import '../../domain/backup/backup_manifest.dart';
import '../../domain/labs/lab_repository.dart';
import '../../domain/measurements/measurement_repository.dart';
import '../../domain/medication/medication_repository.dart';
import '../../domain/notifications/reminder_repository.dart';
import '../../domain/nutrition/food_repository.dart';
import '../../domain/nutrition/meal_repository.dart';
import '../../domain/profile/profile_repository.dart';
import 'backup_codec.dart';

/// Formato do backup: 1 versão em `manifest.json` = a versão da estrutura de
/// dados, não a versão do app.
const String kBackupFormatVersion = '1.0';

/// RF-083 — gera um arquivo de backup completo (zip com `manifest.json` e
/// `data.json`), para compartilhamento via app de Arquivos/iCloud Drive ou
/// equivalente Android — independente da sincronização automática do
/// Firestore, para portabilidade e controle do usuário.
class BackupService {
  BackupService({
    required this.profileRepository,
    required this.foodRepository,
    required this.mealRepository,
    required this.measurementRepository,
    required this.medicationRepository,
    required this.activityRepository,
    required this.labRepository,
    required this.reminderRepository,
  });

  final ProfileRepository profileRepository;
  final FoodRepository foodRepository;
  final MealRepository mealRepository;
  final MeasurementRepository measurementRepository;
  final MedicationRepository medicationRepository;
  final ActivityRepository activityRepository;
  final LabRepository labRepository;
  final ReminderRepository reminderRepository;

  Future<Uint8List> buildBackupArchive() async {
    final farPast = DateTime(2000);
    final farFuture = DateTime(2100);

    final profile = await profileRepository.watchProfile().first;
    final goalHistory = await profileRepository.watchGoalHistory().first;
    final foods = await foodRepository.watchAll().first;
    final meals = await mealRepository.watchRange(farPast, farFuture).first;
    final weights = await measurementRepository.watchWeights().first;
    final bodyMeasures = await measurementRepository.watchBodyMeasures().first;
    final medicationPlans = await medicationRepository.watchPlans().first;
    final medicationEntries = await medicationRepository.watchEntries().first;
    final activityPlans = await activityRepository.watchPlans().first;
    final activityEntries = await activityRepository.watchEntries().first;
    final labResults = await labRepository.watchAll().first;
    final reminders = await reminderRepository.watchAll().first;

    final data = <String, dynamic>{
      'profile': profile == null ? null : BackupCodec.profileToJson(profile),
      'goalHistory': goalHistory.map(BackupCodec.goalToJson).toList(),
      'foods': foods.map(BackupCodec.foodToJson).toList(),
      'meals': meals.map(BackupCodec.mealToJson).toList(),
      'weightEntries': weights.map(BackupCodec.weightToJson).toList(),
      'bodyMeasureEntries': bodyMeasures
          .map(BackupCodec.bodyMeasureToJson)
          .toList(),
      'medicationPlans': medicationPlans
          .map(BackupCodec.medicationPlanToJson)
          .toList(),
      'medicationEntries': medicationEntries
          .map(BackupCodec.medicationEntryToJson)
          .toList(),
      'activityPlans': activityPlans
          .map(BackupCodec.activityPlanToJson)
          .toList(),
      'activityEntries': activityEntries
          .map(BackupCodec.activityEntryToJson)
          .toList(),
      'labResults': labResults.map(BackupCodec.labResultToJson).toList(),
      'reminders': reminders.map(BackupCodec.reminderToJson).toList(),
    };

    final dataBytes = utf8.encode(jsonEncode(data));
    final checksum = sha256.convert(dataBytes).toString();

    final collectionCounts = <String, int>{
      for (final entry in data.entries)
        entry.key: entry.value is List ? (entry.value as List).length : 1,
    };

    final manifest = BackupManifest(
      version: kBackupFormatVersion,
      createdAt: DateTime.now(),
      checksumSha256: checksum,
      collectionCounts: collectionCounts,
    );
    final manifestBytes = utf8.encode(jsonEncode(manifest.toJson()));

    final archive = Archive()
      ..addFile(
        ArchiveFile('manifest.json', manifestBytes.length, manifestBytes),
      )
      ..addFile(ArchiveFile('data.json', dataBytes.length, dataBytes));

    final zipBytes = ZipEncoder().encode(archive);
    return Uint8List.fromList(zipBytes);
  }
}
