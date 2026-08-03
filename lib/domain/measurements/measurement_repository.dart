import 'body_measure_entry.dart';
import 'weight_entry.dart';

abstract class MeasurementRepository {
  Stream<List<WeightEntry>> watchWeights();

  Future<void> saveWeight(WeightEntry entry);

  Future<void> deleteWeight(String id);

  Stream<List<BodyMeasureEntry>> watchBodyMeasures();

  Future<void> saveBodyMeasure(BodyMeasureEntry entry);

  Future<void> deleteBodyMeasure(String id);
}
