import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/labs/lab_result.dart';

class LabResultMapper {
  const LabResultMapper._();

  static Map<String, dynamic> toMap(LabResult result) => {
    'date': Timestamp.fromDate(result.date),
    'markerName': result.markerName,
    'result': result.result,
    'unit': result.unit,
    'reference': result.reference,
    'origin': result.origin,
  };

  static LabResult fromMap(String id, Map<String, dynamic> map) => LabResult(
    id: id,
    date: (map['date'] as Timestamp).toDate(),
    markerName: map['markerName'] as String,
    result: (map['result'] as num).toDouble(),
    unit: map['unit'] as String,
    reference: map['reference'] as String?,
    origin: map['origin'] as String?,
  );
}
