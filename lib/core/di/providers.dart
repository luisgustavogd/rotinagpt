import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth/firebase_auth_gateway.dart';
import '../../data/backup/backup_reader.dart';
import '../../data/backup/backup_service.dart';
import '../../data/health/no_op_health_gateway.dart';
import '../../data/notifications/notification_service.dart';
import '../../data/remote/firestore_paths.dart';
import '../../data/remote/repositories/activity_repository_impl.dart';
import '../../data/remote/repositories/daily_check_repository_impl.dart';
import '../../data/remote/repositories/food_repository_impl.dart';
import '../../data/remote/repositories/lab_repository_impl.dart';
import '../../data/remote/repositories/meal_repository_impl.dart';
import '../../data/remote/repositories/measurement_repository_impl.dart';
import '../../data/remote/repositories/medication_repository_impl.dart';
import '../../data/remote/repositories/profile_repository_impl.dart';
import '../../data/remote/repositories/reminder_repository_impl.dart';
import '../../data/security/no_op_app_lock_gateway.dart';
import '../../domain/activity/activity_repository.dart';
import '../../domain/auth/app_user.dart';
import '../../domain/auth/auth_gateway.dart';
import '../../domain/health/health_gateway.dart';
import '../../domain/labs/lab_repository.dart';
import '../../domain/measurements/measurement_repository.dart';
import '../../domain/medication/medication_repository.dart';
import '../../domain/notifications/daily_check_repository.dart';
import '../../domain/notifications/reminder.dart';
import '../../domain/notifications/reminder_repository.dart';
import '../../domain/nutrition/food_repository.dart';
import '../../domain/nutrition/meal_repository.dart';
import '../../domain/profile/profile_repository.dart';
import '../../domain/security/app_lock_gateway.dart';
import '../local_prefs/app_prefs.dart';
import '../logging/app_logger.dart';

final appLoggerProvider = Provider<AppLogger>((ref) => const AppLogger());

final firebaseAuthProvider = Provider<fb.FirebaseAuth>(
  (ref) => fb.FirebaseAuth.instance,
);

final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

final authGatewayProvider = Provider<AuthGateway>((ref) {
  return FirebaseAuthGateway(firebaseAuth: ref.watch(firebaseAuthProvider));
});

/// Estado de autenticação reativo — a UI (e a guarda de rota) observam este
/// provider para saber se há um usuário logado.
final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authGatewayProvider).authStateChanges();
});

/// uid do usuário atual, ou null se deslogado. Todos os repositórios abaixo
/// dependem disto para montar os caminhos `/users/{uid}/...`.
final currentUidProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.uid;
});

final firestorePathsProvider = Provider<FirestorePaths?>((ref) {
  final uid = ref.watch(currentUidProvider);
  return uid == null ? null : FirestorePaths(uid);
});

final appPrefsProvider = FutureProvider<AppPrefs>((ref) => AppPrefs.create());

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

final healthGatewayProvider = Provider<HealthGateway>(
  (ref) => const NoOpHealthGateway(),
);

final appLockGatewayProvider = Provider<AppLockGateway>(
  (ref) => const NoOpAppLockGateway(),
);

// --- Repositórios (dependem do usuário autenticado) -------------------------
//
// Cada provider assume que `firestorePathsProvider` não é null — só deve ser
// lido depois que a guarda de rota (`app/router.dart`) já garantiu que há um
// usuário autenticado.

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(
    ref.watch(firestoreProvider),
    ref.watch(firestorePathsProvider)!,
  );
});

final foodRepositoryProvider = Provider<FoodRepository>((ref) {
  return FoodRepositoryImpl(
    ref.watch(firestoreProvider),
    ref.watch(firestorePathsProvider)!,
  );
});

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  return MealRepositoryImpl(
    ref.watch(firestoreProvider),
    ref.watch(firestorePathsProvider)!,
  );
});

final measurementRepositoryProvider = Provider<MeasurementRepository>((ref) {
  return MeasurementRepositoryImpl(
    ref.watch(firestoreProvider),
    ref.watch(firestorePathsProvider)!,
  );
});

final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  return MedicationRepositoryImpl(
    ref.watch(firestoreProvider),
    ref.watch(firestorePathsProvider)!,
  );
});

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepositoryImpl(
    ref.watch(firestoreProvider),
    ref.watch(firestorePathsProvider)!,
  );
});

final labRepositoryProvider = Provider<LabRepository>((ref) {
  return LabRepositoryImpl(
    ref.watch(firestoreProvider),
    ref.watch(firestorePathsProvider)!,
  );
});

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  return ReminderRepositoryImpl(
    ref.watch(firestoreProvider),
    ref.watch(firestorePathsProvider)!,
  );
});

final dailyCheckRepositoryProvider = Provider<DailyCheckRepository>((ref) {
  return DailyCheckRepositoryImpl(
    ref.watch(firestoreProvider),
    ref.watch(firestorePathsProvider)!,
  );
});

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    profileRepository: ref.watch(profileRepositoryProvider),
    foodRepository: ref.watch(foodRepositoryProvider),
    mealRepository: ref.watch(mealRepositoryProvider),
    measurementRepository: ref.watch(measurementRepositoryProvider),
    medicationRepository: ref.watch(medicationRepositoryProvider),
    activityRepository: ref.watch(activityRepositoryProvider),
    labRepository: ref.watch(labRepositoryProvider),
    reminderRepository: ref.watch(reminderRepositoryProvider),
  );
});

final backupReaderProvider = Provider<BackupReader>((ref) {
  return BackupReader(
    firestore: ref.watch(firestoreProvider),
    paths: ref.watch(firestorePathsProvider)!,
  );
});

/// RF-064/RN-009 — usado por `app/app.dart` para reagendar as notificações
/// locais deste aparelho sempre que a lista de lembretes mudar (local ou
/// sincronizada de outro aparelho). Emite uma lista vazia enquanto
/// deslogado, para nunca tentar ler `/users/{uid}/...` sem uid.
final remindersStreamProvider = StreamProvider.autoDispose<List<Reminder>>((
  ref,
) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const <Reminder>[]);
  return ref.watch(reminderRepositoryProvider).watchAll();
});
