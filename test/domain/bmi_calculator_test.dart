import 'package:flutter_test/flutter_test.dart';
import 'package:rotinagpt/domain/profile/bmi_calculator.dart';

void main() {
  test('calcula o IMC a partir de peso e altura', () {
    expect(BmiCalculator.bmi(85, 170), closeTo(29.41, 0.01));
  });

  test('retorna null sem altura válida', () {
    expect(BmiCalculator.bmi(85, null), isNull);
    expect(BmiCalculator.bmi(85, 0), isNull);
  });

  test('sugere o peso correspondente ao IMC central (21,75) para a altura', () {
    expect(BmiCalculator.suggestedTargetWeightKg(170), closeTo(62.86, 0.01));
  });

  test('sugestão de peso retorna null sem altura válida', () {
    expect(BmiCalculator.suggestedTargetWeightKg(null), isNull);
  });
}
