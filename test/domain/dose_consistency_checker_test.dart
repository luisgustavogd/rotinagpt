import 'package:flutter_test/flutter_test.dart';
import 'package:rotinagpt/domain/medication/dose_consistency_checker.dart';
import 'package:rotinagpt/domain/medication/medication_plan.dart';

void main() {
  const checker = DoseConsistencyChecker();
  const plan = MedicationPlan(
    id: 'p1',
    name: 'Tirzepatida',
    prescribedDose: '5mg',
    frequency: 'semanal',
    weekdays: [1],
    time: '08:00',
  );

  test('RF-045: dose divergente exige confirmação', () {
    expect(
      checker.needsConfirmation(plan: plan, registeredDose: '7.5mg'),
      isTrue,
    );
  });

  test('dose igual (mesmo com espaços/maiúsculas) não exige confirmação', () {
    expect(
      checker.needsConfirmation(plan: plan, registeredDose: ' 5MG '),
      isFalse,
    );
  });
}
