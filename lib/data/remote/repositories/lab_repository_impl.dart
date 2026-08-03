import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/labs/lab_repository.dart';
import '../../../domain/labs/lab_result.dart';
import '../firestore_paths.dart';
import '../mappers/lab_mapper.dart';

class LabRepositoryImpl implements LabRepository {
  LabRepositoryImpl(this._firestore, this._paths);

  final FirebaseFirestore _firestore;
  final FirestorePaths _paths;

  @override
  Stream<List<LabResult>> watchAll() {
    return _firestore
        .collection(_paths.labResults)
        .orderBy('date')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => LabResultMapper.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  @override
  Future<void> save(LabResult result) {
    return _firestore
        .collection(_paths.labResults)
        .doc(result.id)
        .set(LabResultMapper.toMap(result));
  }

  @override
  Future<void> delete(String id) {
    return _firestore.collection(_paths.labResults).doc(id).delete();
  }
}
