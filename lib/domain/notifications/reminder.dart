enum ReminderType { meal, protein, activity, weight, medication }

enum ReminderRecurrence { once, daily, weekly }

/// RF-060 — lembrete local. RF-064 — a definição é reagendada sempre que
/// horários/rotina mudam (o consumidor deve chamar o scheduler novamente
/// após qualquer edição).
class Reminder {
  const Reminder({
    required this.id,
    required this.type,
    required this.time,
    required this.recurrence,
    this.weekdays = const [],
    required this.active,
    this.relatedItemId,
    this.label,
  });

  final String id;
  final ReminderType type;

  /// "HH:mm".
  final String time;
  final ReminderRecurrence recurrence;

  /// Só relevante para [ReminderRecurrence.weekly]; 1 (segunda) a 7 (domingo).
  final List<int> weekdays;

  /// RN-009 — quando false, o lembrete deve ser removido do agendamento do
  /// sistema operacional.
  final bool active;
  final String? relatedItemId;
  final String? label;
}
