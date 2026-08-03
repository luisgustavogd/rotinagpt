import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/measurements/body_measure_entry.dart';
import '../../../domain/measurements/weight_entry.dart';

class WeightEntryMapper {
  const WeightEntryMapper._();

  static Map<String, dynamic> toMap(WeightEntry entry) => {
    'dateTime': Timestamp.fromDate(entry.dateTime),
    'weightKg': entry.weightKg,
    'observation': entry.observation,
  };

  static WeightEntry fromMap(String id, Map<String, dynamic> map) =>
      WeightEntry(
        id: id,
        dateTime: (map['dateTime'] as Timestamp).toDate(),
        weightKg: (map['weightKg'] as num).toDouble(),
        observation: map['observation'] as String?,
      );
}

class BodyMeasureEntryMapper {
  const BodyMeasureEntryMapper._();

  static Map<String, dynamic> toMap(BodyMeasureEntry entry) => {
    'date': Timestamp.fromDate(entry.date),
    'waistCm': entry.waistCm,
    'observation': entry.observation,
  };

  static BodyMeasureEntry fromMap(String id, Map<String, dynamic> map) =>
      BodyMeasureEntry(
        id: id,
        date: (map['date'] as Timestamp).toDate(),
        waistCm: (map['waistCm'] as num).toDouble(),
        observation: map['observation'] as String?,
      );
}
