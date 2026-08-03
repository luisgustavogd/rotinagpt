import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/medication/medication_entry.dart';
import '../../../domain/medication/medication_plan.dart';

class MedicationPlanMapper {
  const MedicationPlanMapper._();

  static Map<String, dynamic> toMap(MedicationPlan plan) => {
    'name': plan.name,
    'prescribedDose': plan.prescribedDose,
    'frequency': plan.frequency,
    'weekdays': plan.weekdays,
    'time': plan.time,
  };

  static MedicationPlan fromMap(String id, Map<String, dynamic> map) =>
      MedicationPlan(
        id: id,
        name: map['name'] as String,
        prescribedDose: map['prescribedDose'] as String,
        frequency: map['frequency'] as String,
        weekdays: List<int>.from(map['weekdays'] as List),
        time: map['time'] as String,
      );
}

class MedicationEntryMapper {
  const MedicationEntryMapper._();

  static Map<String, dynamic> toMap(MedicationEntry entry) => {
    'planId': entry.planId,
    'dateTime': Timestamp.fromDate(entry.dateTime),
    'dose': entry.dose,
    'applicationSite': entry.applicationSite,
    'symptoms': entry.symptoms
        .map((s) => {'name': s.name, 'intensity': s.intensity})
        .toList(),
    'observation': entry.observation,
  };

  static MedicationEntry fromMap(String id, Map<String, dynamic> map) =>
      MedicationEntry(
        id: id,
        planId: map['planId'] as String,
        dateTime: (map['dateTime'] as Timestamp).toDate(),
        dose: map['dose'] as String,
        applicationSite: map['applicationSite'] as String,
        symptoms: (map['symptoms'] as List? ?? [])
            .map(
              (s) => SymptomRecord(
                name: (s as Map)['name'] as String,
                intensity: s['intensity'] as int,
              ),
            )
            .toList(),
        observation: map['observation'] as String?,
      );
}
