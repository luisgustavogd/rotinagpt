import 'lab_result.dart';

abstract class LabRepository {
  Stream<List<LabResult>> watchAll();

  Future<void> save(LabResult result);

  Future<void> delete(String id);
}
