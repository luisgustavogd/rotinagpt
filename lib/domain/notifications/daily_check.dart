/// RF-012 — item do checklist diário (refeição, hidratação, atividade,
/// hábito opcional configurado pelo usuário, etc).
enum DailyCheckStatus { pending, done }

class DailyCheck {
  const DailyCheck({
    required this.id,
    required this.date,
    required this.habitLabel,
    required this.status,
    this.completedAt,
  });

  final String id;
  final DateTime date;
  final String habitLabel;
  final DailyCheckStatus status;
  final DateTime? completedAt;

  DailyCheck copyWith({DailyCheckStatus? status, DateTime? completedAt}) {
    return DailyCheck(
      id: id,
      date: date,
      habitLabel: habitLabel,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
