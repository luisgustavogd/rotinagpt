import '../../domain/activity/activity_entry.dart';
import '../../domain/activity/activity_plan.dart';
import '../../domain/activity/activity_type.dart';
import '../../domain/labs/lab_result.dart';
import '../../domain/measurements/body_measure_entry.dart';
import '../../domain/measurements/weight_entry.dart';
import '../../domain/medication/medication_entry.dart';
import '../../domain/medication/medication_plan.dart';
import '../../domain/notifications/reminder.dart';
import '../../domain/nutrition/food.dart';
import '../../domain/nutrition/meal_entry.dart';
import '../../domain/nutrition/meal_item.dart';
import '../../domain/nutrition/meal_unit.dart';
import '../../domain/profile/goal_history_entry.dart';
import '../../domain/profile/protein_target_calculator.dart';
import '../../domain/profile/user_profile.dart';

/// Codec de JSON puro (datas como ISO-8601, sem `Timestamp` do Firestore)
/// usado só pelo backup/restauração — formato de arquivo portátil,
/// independente do backend de sincronização.
class BackupCodec {
  const BackupCodec._();

  static Map<String, dynamic> profileToJson(UserProfile p) => {
    'name': p.name,
    'initialWeightKg': p.initialWeightKg,
    'heightCm': p.heightCm,
    'targetWeightKg': p.targetWeightKg,
    'targetProteinG': p.targetProteinG,
    'proteinActivityLevel': p.proteinActivityLevel?.name,
    'wakeTime': p.wakeTime,
    'sleepTime': p.sleepTime,
    'restrictions': p.restrictions,
    'avoidedFoods': p.avoidedFoods,
    'noEatAfter': p.noEatAfter,
  };

  static UserProfile profileFromJson(Map<String, dynamic> j) => UserProfile(
    name: j['name'] as String?,
    initialWeightKg: (j['initialWeightKg'] as num).toDouble(),
    heightCm: (j['heightCm'] as num?)?.toDouble(),
    targetWeightKg: (j['targetWeightKg'] as num).toDouble(),
    targetProteinG: (j['targetProteinG'] as num).toDouble(),
    proteinActivityLevel: (j['proteinActivityLevel'] as String?) == null
        ? null
        : ProteinActivityLevel.values.byName(
            j['proteinActivityLevel'] as String,
          ),
    wakeTime: j['wakeTime'] as String,
    sleepTime: j['sleepTime'] as String,
    restrictions: List<String>.from(j['restrictions'] as List? ?? []),
    avoidedFoods: List<String>.from(j['avoidedFoods'] as List? ?? []),
    noEatAfter: j['noEatAfter'] as String?,
  );

  static Map<String, dynamic> goalToJson(GoalHistoryEntry g) => {
    'id': g.id,
    'kind': g.kind.name,
    'value': g.value,
    'effectiveDate': g.effectiveDate.toIso8601String(),
  };

  static GoalHistoryEntry goalFromJson(Map<String, dynamic> j) =>
      GoalHistoryEntry(
        id: j['id'] as String,
        kind: GoalKind.values.byName(j['kind'] as String),
        value: (j['value'] as num).toDouble(),
        effectiveDate: DateTime.parse(j['effectiveDate'] as String),
      );

  static Map<String, dynamic> foodToJson(Food f) => {
    'id': f.id,
    'name': f.name,
    'defaultPortion': f.defaultPortion,
    'unit': f.unit.name,
    'proteinG': f.proteinG,
    'caloriesKcal': f.caloriesKcal,
    'favorite': f.favorite,
  };

  static Food foodFromJson(Map<String, dynamic> j) => Food(
    id: j['id'] as String,
    name: j['name'] as String,
    defaultPortion: (j['defaultPortion'] as num).toDouble(),
    unit: MealUnit.values.byName(j['unit'] as String),
    proteinG: (j['proteinG'] as num).toDouble(),
    caloriesKcal: (j['caloriesKcal'] as num?)?.toDouble(),
    favorite: j['favorite'] as bool? ?? false,
  );

  static Map<String, dynamic> mealToJson(MealEntry m) => {
    'id': m.id,
    'dateTime': m.dateTime.toIso8601String(),
    'mealType': m.mealType.name,
    'status': m.status.name,
    'items': m.items
        .map(
          (i) => {
            'foodId': i.foodId,
            'foodNameSnapshot': i.foodNameSnapshot,
            'quantity': i.quantity,
            'unit': i.unit.name,
            'proteinG': i.proteinG,
            'caloriesKcal': i.caloriesKcal,
          },
        )
        .toList(),
    'toleranceSymptoms': m.toleranceSymptoms.map((s) => s.name).toList(),
    'observation': m.observation,
  };

  static MealEntry mealFromJson(Map<String, dynamic> j) => MealEntry(
    id: j['id'] as String,
    dateTime: DateTime.parse(j['dateTime'] as String),
    mealType: MealType.values.byName(j['mealType'] as String),
    status: MealStatus.values.byName(j['status'] as String),
    items: (j['items'] as List)
        .map(
          (i) => MealItem(
            foodId: i['foodId'] as String,
            foodNameSnapshot: i['foodNameSnapshot'] as String,
            quantity: (i['quantity'] as num).toDouble(),
            unit: MealUnit.values.byName(i['unit'] as String),
            proteinG: (i['proteinG'] as num).toDouble(),
            caloriesKcal: (i['caloriesKcal'] as num?)?.toDouble(),
          ),
        )
        .toList(),
    toleranceSymptoms: (j['toleranceSymptoms'] as List? ?? [])
        .map((s) => ToleranceSymptom.values.byName(s as String))
        .toList(),
    observation: j['observation'] as String?,
  );

  static Map<String, dynamic> weightToJson(WeightEntry w) => {
    'id': w.id,
    'dateTime': w.dateTime.toIso8601String(),
    'weightKg': w.weightKg,
    'observation': w.observation,
  };

  static WeightEntry weightFromJson(Map<String, dynamic> j) => WeightEntry(
    id: j['id'] as String,
    dateTime: DateTime.parse(j['dateTime'] as String),
    weightKg: (j['weightKg'] as num).toDouble(),
    observation: j['observation'] as String?,
  );

  static Map<String, dynamic> bodyMeasureToJson(BodyMeasureEntry b) => {
    'id': b.id,
    'date': b.date.toIso8601String(),
    'waistCm': b.waistCm,
    'observation': b.observation,
  };

  static BodyMeasureEntry bodyMeasureFromJson(Map<String, dynamic> j) =>
      BodyMeasureEntry(
        id: j['id'] as String,
        date: DateTime.parse(j['date'] as String),
        waistCm: (j['waistCm'] as num).toDouble(),
        observation: j['observation'] as String?,
      );

  static Map<String, dynamic> medicationPlanToJson(MedicationPlan p) => {
    'id': p.id,
    'name': p.name,
    'prescribedDose': p.prescribedDose,
    'frequency': p.frequency,
    'weekdays': p.weekdays,
    'time': p.time,
  };

  static MedicationPlan medicationPlanFromJson(Map<String, dynamic> j) =>
      MedicationPlan(
        id: j['id'] as String,
        name: j['name'] as String,
        prescribedDose: j['prescribedDose'] as String,
        frequency: j['frequency'] as String,
        weekdays: List<int>.from(j['weekdays'] as List),
        time: j['time'] as String,
      );

  static Map<String, dynamic> medicationEntryToJson(MedicationEntry e) => {
    'id': e.id,
    'planId': e.planId,
    'dateTime': e.dateTime.toIso8601String(),
    'dose': e.dose,
    'applicationSite': e.applicationSite,
    'symptoms': e.symptoms
        .map((s) => {'name': s.name, 'intensity': s.intensity})
        .toList(),
    'observation': e.observation,
  };

  static MedicationEntry medicationEntryFromJson(Map<String, dynamic> j) =>
      MedicationEntry(
        id: j['id'] as String,
        planId: j['planId'] as String,
        dateTime: DateTime.parse(j['dateTime'] as String),
        dose: j['dose'] as String,
        applicationSite: j['applicationSite'] as String,
        symptoms: (j['symptoms'] as List? ?? [])
            .map(
              (s) => SymptomRecord(
                name: (s as Map)['name'] as String,
                intensity: s['intensity'] as int,
              ),
            )
            .toList(),
        observation: j['observation'] as String?,
      );

  static Map<String, dynamic> activityPlanToJson(ActivityPlan p) => {
    'id': p.id,
    'weekday': p.weekday,
    'type': p.type.name,
    'durationMin': p.durationMin,
    'perceivedIntensity': p.perceivedIntensity,
    'observation': p.observation,
    'active': p.active,
  };

  static ActivityPlan activityPlanFromJson(Map<String, dynamic> j) =>
      ActivityPlan(
        id: j['id'] as String,
        weekday: j['weekday'] as int,
        type: ActivityType.values.byName(j['type'] as String),
        durationMin: j['durationMin'] as int,
        perceivedIntensity: j['perceivedIntensity'] as int,
        observation: j['observation'] as String?,
        active: j['active'] as bool? ?? true,
      );

  static Map<String, dynamic> activityEntryToJson(ActivityEntry e) => {
    'id': e.id,
    'planId': e.planId,
    'dateTime': e.dateTime.toIso8601String(),
    'type': e.type.name,
    'durationMin': e.durationMin,
    'perceivedEffort': e.perceivedEffort,
    'status': e.status.name,
    'observation': e.observation,
  };

  static ActivityEntry activityEntryFromJson(Map<String, dynamic> j) =>
      ActivityEntry(
        id: j['id'] as String,
        planId: j['planId'] as String?,
        dateTime: DateTime.parse(j['dateTime'] as String),
        type: ActivityType.values.byName(j['type'] as String),
        durationMin: j['durationMin'] as int,
        perceivedEffort: j['perceivedEffort'] as int,
        status: ActivityStatus.values.byName(j['status'] as String),
        observation: j['observation'] as String?,
      );

  static Map<String, dynamic> labResultToJson(LabResult r) => {
    'id': r.id,
    'date': r.date.toIso8601String(),
    'markerName': r.markerName,
    'result': r.result,
    'unit': r.unit,
    'reference': r.reference,
    'origin': r.origin,
  };

  static LabResult labResultFromJson(Map<String, dynamic> j) => LabResult(
    id: j['id'] as String,
    date: DateTime.parse(j['date'] as String),
    markerName: j['markerName'] as String,
    result: (j['result'] as num).toDouble(),
    unit: j['unit'] as String,
    reference: j['reference'] as String?,
    origin: j['origin'] as String?,
  );

  static Map<String, dynamic> reminderToJson(Reminder r) => {
    'id': r.id,
    'type': r.type.name,
    'time': r.time,
    'recurrence': r.recurrence.name,
    'weekdays': r.weekdays,
    'active': r.active,
    'relatedItemId': r.relatedItemId,
    'label': r.label,
  };

  static Reminder reminderFromJson(Map<String, dynamic> j) => Reminder(
    id: j['id'] as String,
    type: ReminderType.values.byName(j['type'] as String),
    time: j['time'] as String,
    recurrence: ReminderRecurrence.values.byName(j['recurrence'] as String),
    weekdays: List<int>.from(j['weekdays'] as List? ?? []),
    active: j['active'] as bool? ?? true,
    relatedItemId: j['relatedItemId'] as String?,
    label: j['label'] as String?,
  );
}
