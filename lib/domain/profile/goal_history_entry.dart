enum GoalKind { weight, protein }

/// RN-008 — metas alteradas valem a partir da data da mudança, preservando
/// histórico. Append-only: nunca editar/apagar uma entrada existente, apenas
/// adicionar uma nova com `effectiveDate` mais recente.
class GoalHistoryEntry {
  const GoalHistoryEntry({
    required this.id,
    required this.kind,
    required this.value,
    required this.effectiveDate,
  });

  final String id;
  final GoalKind kind;
  final double value;
  final DateTime effectiveDate;

  /// Valor da meta vigente em [at], considerando apenas entradas cujo
  /// `effectiveDate` já passou.
  static double? valueAt(
    List<GoalHistoryEntry> history,
    GoalKind kind,
    DateTime at,
  ) {
    final applicable =
        history
            .where((e) => e.kind == kind && !e.effectiveDate.isAfter(at))
            .toList()
          ..sort((a, b) => a.effectiveDate.compareTo(b.effectiveDate));
    return applicable.isEmpty ? null : applicable.last.value;
  }
}
