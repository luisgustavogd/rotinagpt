import 'medication_plan.dart';

/// RF-045 — se a dose registrada diverge da cadastrada no plano, o app pede
/// confirmação ao usuário. RF-044 — em nenhuma hipótese o app sugere
/// aumentar, reduzir, atrasar, antecipar ou interromper a dose: esta classe
/// só sinaliza a divergência, nunca recomenda uma conduta.
class DoseConsistencyChecker {
  const DoseConsistencyChecker();

  /// true quando a dose informada no registro difere da dose prescrita no
  /// plano (comparação textual normalizada) — a UI deve então pedir
  /// confirmação explícita antes de salvar, sem sugerir qual dose é "certa".
  bool needsConfirmation({
    required MedicationPlan plan,
    required String registeredDose,
  }) {
    return _normalize(plan.prescribedDose) != _normalize(registeredDose);
  }

  String _normalize(String dose) =>
      dose.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
}
