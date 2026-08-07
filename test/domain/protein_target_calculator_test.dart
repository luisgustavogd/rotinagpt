import 'package:flutter_test/flutter_test.dart';
import 'package:rotinagpt/domain/profile/protein_target_calculator.dart';

void main() {
  test('sedentário usa 0,8 g/kg (RDA)', () {
    expect(
      ProteinTargetCalculator.suggestedTargetProteinG(
        80,
        ProteinActivityLevel.sedentary,
      ),
      closeTo(64, 0.01),
    );
  });

  test('ativo sem déficit usa o centro da faixa 1,4-2,0 g/kg (1,7)', () {
    expect(
      ProteinTargetCalculator.suggestedTargetProteinG(
        80,
        ProteinActivityLevel.active,
      ),
      closeTo(136, 0.01),
    );
  });

  test(
    'déficit calórico com treino de força usa o centro da faixa 2,3-3,1 g/kg (2,7)',
    () {
      expect(
        ProteinTargetCalculator.suggestedTargetProteinG(
          80,
          ProteinActivityLevel.caloricDeficitTraining,
        ),
        closeTo(216, 0.01),
      );
    },
  );
}
