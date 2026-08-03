/// Centraliza os caminhos do Firestore. Tudo sob `/users/{uid}/...`, para
/// casar com as Security Rules (`firestore.rules`) que restringem cada
/// documento ao próprio `uid` autenticado.
class FirestorePaths {
  const FirestorePaths(this.uid);

  final String uid;

  String get _root => 'users/$uid';

  String get profileDoc => '$_root/profile/main';
  String get settingsDoc => '$_root/settings/main';
  String get goalHistory => '$_root/goalHistory';
  String get foods => '$_root/foods';
  String get meals => '$_root/meals';
  String get weightEntries => '$_root/weightEntries';
  String get bodyMeasureEntries => '$_root/bodyMeasureEntries';
  String get medicationPlans => '$_root/medicationPlans';
  String get medicationEntries => '$_root/medicationEntries';
  String get activityPlans => '$_root/activityPlans';
  String get activityEntries => '$_root/activityEntries';
  String get labResults => '$_root/labResults';
  String get reminders => '$_root/reminders';
  String get dailyChecks => '$_root/dailyChecks';
  String get attachments => '$_root/attachments';
}
